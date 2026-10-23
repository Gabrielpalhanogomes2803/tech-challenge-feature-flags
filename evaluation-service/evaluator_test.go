package main

import "testing"

func TestRunEvaluationLogic(t *testing.T) {
	app := &App{}

	tests := []struct {
		name     string
		info     *CombinedFlagInfo
		userID   string
		expected bool
	}{
		{
			name: "flag desativada",
			info: &CombinedFlagInfo{
				Flag: &Flag{Name: "feature-a", IsEnabled: false},
			},
			userID:   "user-1",
			expected: false,
		},
		{
			name: "flag ativada sem regra",
			info: &CombinedFlagInfo{
				Flag: &Flag{Name: "feature-a", IsEnabled: true},
			},
			userID:   "user-1",
			expected: true,
		},
		{
			name: "regra desativada",
			info: &CombinedFlagInfo{
				Flag: &Flag{Name: "feature-a", IsEnabled: true},
				Rule: &TargetingRule{IsEnabled: false},
			},
			userID:   "user-1",
			expected: true,
		},
		{
			name: "percentual zero",
			info: &CombinedFlagInfo{
				Flag: &Flag{Name: "feature-a", IsEnabled: true},
				Rule: &TargetingRule{
					IsEnabled: true,
					Rules: Rule{
						Type:  "PERCENTAGE",
						Value: float64(0),
					},
				},
			},
			userID:   "user-1",
			expected: false,
		},
		{
			name: "percentual cem",
			info: &CombinedFlagInfo{
				Flag: &Flag{Name: "feature-a", IsEnabled: true},
				Rule: &TargetingRule{
					IsEnabled: true,
					Rules: Rule{
						Type:  "PERCENTAGE",
						Value: float64(100),
					},
				},
			},
			userID:   "user-1",
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			actual := app.runEvaluationLogic(tt.info, tt.userID)

			if actual != tt.expected {
				t.Errorf(
					"resultado incorreto: esperado=%v, obtido=%v",
					tt.expected,
					actual,
				)
			}
		})
	}
}
