package main

import (
	"crypto/sha1"
	"encoding/binary"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/go-redis/redis/v8"
)

const (
	CACHE_TTL = 30 * time.Second
)

func (a *App) getDecision(userID, flagName string) (bool, error) {
	info, err := a.getCombinedFlagInfo(flagName)
	if err != nil {
		return false, err
	}

	return a.runEvaluationLogic(info, userID), nil
}

func (a *App) getCombinedFlagInfo(flagName string) (*CombinedFlagInfo, error) {
	cacheKey := fmt.Sprintf("flag_info:%s", flagName)

	val, err := a.RedisClient.Get(ctx, cacheKey).Result()

	if err == nil {
		var info CombinedFlagInfo

		if err := json.Unmarshal([]byte(val), &info); err == nil {
			writeLog("info", "cache_hit", LogEvent{
				Component:  "cache",
				Dependency: "redis",
			})

			return &info, nil
		}

		writeLog("warn", "cache_deserialize_error", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "failed to decode cached value",
		})
	} else if err != redis.Nil {
		writeLog("error", "redis_error", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "failed to read cache",
		})
	}

	writeLog("info", "cache_miss", LogEvent{
		Component:  "cache",
		Dependency: "redis",
	})

	info, err := a.fetchFromServices(flagName)
	if err != nil {
		return nil, err
	}

	jsonData, err := json.Marshal(info)
	if err != nil {
		writeLog("warn", "cache_serialize_error", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "failed to encode cache value",
		})

		return info, nil
	}

	if err := a.RedisClient.Set(ctx, cacheKey, jsonData, CACHE_TTL).Err(); err != nil {
		writeLog("error", "redis_error", LogEvent{
			Component:  "cache",
			Dependency: "redis",
			Message:    "failed to update cache",
		})
	}

	return info, nil
}

func (a *App) fetchFromServices(flagName string) (*CombinedFlagInfo, error) {
	var wg sync.WaitGroup
	wg.Add(2)

	var flagInfo *Flag
	var ruleInfo *TargetingRule
	var flagErr, ruleErr error

	go func() {
		defer wg.Done()
		flagInfo, flagErr = a.fetchFlag(flagName)
	}()

	go func() {
		defer wg.Done()
		ruleInfo, ruleErr = a.fetchRule(flagName)
	}()

	wg.Wait()

	if flagErr != nil {
		writeLog("error", "dependency_error", LogEvent{
			Component:  "http-client",
			Dependency: "flag-service",
			Message:    "failed to retrieve flag",
		})

		return nil, flagErr
	}

	if ruleErr != nil {
		writeLog("warn", "dependency_degraded", LogEvent{
			Component:  "http-client",
			Dependency: "targeting-service",
			Message:    "targeting rule unavailable, using default behavior",
		})
	}

	return &CombinedFlagInfo{
		Flag: flagInfo,
		Rule: ruleInfo,
	}, nil
}

var validFlagName = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$`)

func buildServiceURL(baseURL, resource, flagName string) (string, error) {
	if !validFlagName.MatchString(flagName) {
		return "", fmt.Errorf("nome de flag inválido")
	}

	parsedBase, err := url.Parse(baseURL)
	if err != nil {
		return "", fmt.Errorf("URL base inválida: %w", err)
	}

	if (parsedBase.Scheme != "http" && parsedBase.Scheme != "https") ||
		parsedBase.Host == "" || parsedBase.User != nil {
		return "", fmt.Errorf("URL base de serviço não permitida")
	}

	parsedBase.RawQuery = ""
	parsedBase.Fragment = ""

	return strings.TrimRight(parsedBase.String(), "/") +
		"/" + resource + "/" + url.PathEscape(flagName), nil
}

func (a *App) fetchFlag(flagName string) (*Flag, error) {
	started := time.Now()

	endpoint, err := buildServiceURL(a.FlagServiceURL, "flags", flagName)
	if err != nil {
		return nil, fmt.Errorf("URL do flag-service inválida: %w", err)
	}

	apiKey := os.Getenv("SERVICE_API_KEY")

	// #nosec G704 -- endpoint usa URL base confiável e flagName validado e escapado.
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("erro ao criar requisição para flag-service: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704 -- endpoint foi validado por buildServiceURL.
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		writeLog("error", "dependency_error", LogEvent{
			Component:  "http-client",
			Dependency: "flag-service",
			DurationMS: time.Since(started).Milliseconds(),
			Message:    "request failed",
		})

		return nil, fmt.Errorf("erro ao chamar flag-service: %w", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}

	if resp.StatusCode != http.StatusOK {
		writeLog("error", "dependency_error", LogEvent{
			Component:  "http-client",
			Dependency: "flag-service",
			StatusCode: resp.StatusCode,
			DurationMS: time.Since(started).Milliseconds(),
			Message:    "unexpected response status",
		})

		return nil, fmt.Errorf("flag-service retornou status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler resposta do flag-service: %w", err)
	}

	var flag Flag

	if err := json.Unmarshal(body, &flag); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do flag-service: %w", err)
	}

	return &flag, nil
}

func (a *App) fetchRule(flagName string) (*TargetingRule, error) {
	started := time.Now()

	endpoint, err := buildServiceURL(a.TargetingServiceURL, "rules", flagName)
	if err != nil {
		return nil, fmt.Errorf("URL do targeting-service inválida: %w", err)
	}

	apiKey := os.Getenv("SERVICE_API_KEY")

	// #nosec G704 -- endpoint usa URL base confiável e flagName validado e escapado.
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("erro ao criar requisição para targeting-service: %w", err)
	}

	req.Header.Set("Authorization", "Bearer "+apiKey)

	// #nosec G704 -- endpoint foi validado por buildServiceURL.
	resp, err := a.HttpClient.Do(req)
	if err != nil {
		writeLog("error", "dependency_error", LogEvent{
			Component:  "http-client",
			Dependency: "targeting-service",
			DurationMS: time.Since(started).Milliseconds(),
			Message:    "request failed",
		})

		return nil, fmt.Errorf("erro ao chamar targeting-service: %w", err)
	}

	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return nil, &NotFoundError{flagName}
	}

	if resp.StatusCode != http.StatusOK {
		writeLog("error", "dependency_error", LogEvent{
			Component:  "http-client",
			Dependency: "targeting-service",
			StatusCode: resp.StatusCode,
			DurationMS: time.Since(started).Milliseconds(),
			Message:    "unexpected response status",
		})

		return nil, fmt.Errorf("targeting-service retornou status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler resposta do targeting-service: %w", err)
	}

	var rule TargetingRule

	if err := json.Unmarshal(body, &rule); err != nil {
		return nil, fmt.Errorf("erro ao desserializar resposta do targeting-service: %w", err)
	}

	return &rule, nil
}

func (a *App) runEvaluationLogic(info *CombinedFlagInfo, userID string) bool {
	if info.Flag == nil || !info.Flag.IsEnabled {
		return false
	}

	if info.Rule == nil || !info.Rule.IsEnabled {
		return true
	}

	rule := info.Rule.Rules

	if rule.Type == "PERCENTAGE" {
		percentage, ok := rule.Value.(float64)

		if !ok {
			writeLog("error", "evaluation_failed", LogEvent{
				Component: "evaluation",
				Message:   "percentage rule contains invalid value",
			})

			return false
		}

		userBucket := getDeterministicBucket(userID + info.Flag.Name)

		if float64(userBucket) < percentage {
			return true
		}
	}

	return false
}

func getDeterministicBucket(input string) int {
	hasher := sha1.New()
	hasher.Write([]byte(input))
	hash := hasher.Sum(nil)

	val := binary.BigEndian.Uint32(hash[:4])

	return int(val % 100)
}
