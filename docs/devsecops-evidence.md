# Evidência DevSecOps — bloqueio de configurações críticas

## Objetivo

Demonstrar que o pipeline impede a promoção quando encontra vulnerabilidade ou configuração crítica e somente libera a execução depois da correção.

## Cenário de falha

Na análise do commit `11e52af`, o job `SCA - Repository` executou o Trivy filesystem com os scanners de vulnerabilidades, secrets e misconfigurations.

O pipeline foi bloqueado com três achados críticos:

| Regra | Recurso | Problema |
|---|---|---|
| `AWS-0104` | Security Group do RDS | Egress irrestrito para `0.0.0.0/0` |
| `AWS-0104` | Security Group do Redis | Egress irrestrito para `0.0.0.0/0` |
| `AWS-0040` | Cluster EKS | Endpoint público da API habilitado |

Resultado observado:

- build, testes e lint aprovados;
- Trivy encontrou severidade `CRITICAL`;
- job retornou exit code `1`;
- pipeline ficou vermelho;
- nenhuma imagem foi promovida pelo CD.

## Correção

No commit `3e97f3a` foram aplicadas as seguintes medidas:

1. Remoção do egress irrestrito do Security Group do RDS;
2. Remoção do egress irrestrito do Security Group do Redis;
3. Desativação do endpoint público do EKS;
4. Manutenção exclusiva do endpoint privado do cluster.

As mudanças foram validadas com:

```bash
terraform fmt -recursive -check
terraform init -backend=false
terraform validate
trivy fs --scanners vuln,secret,misconfig --severity CRITICAL --exit-code 1 .
```

## Resultado após a correção

- Terraform válido;
- Trivy filesystem sem achados críticos;
- Gosec e Bandit aprovados;
- cinco builds e scans de containers aprovados;
- pipeline completamente verde.

## Evidências para o vídeo

Durante a gravação, mostrar nesta ordem:

1. Execução vermelha do job `SCA - Repository`;
2. As regras `AWS-0104` e `AWS-0040` no log;
3. Diff entre os commits `11e52af` e `3e97f3a`;
4. Execução posterior totalmente verde;
5. Explicar que o CD depende do sucesso do CI e não promove uma execução reprovada.

Comando útil para demonstrar o diff:

```bash
git diff 11e52af..3e97f3a -- terraform/
```

## Conclusão

A política obrigatória foi atendida: achados críticos retornam exit code diferente de zero, bloqueiam o pipeline e impedem a promoção até que a configuração seja corrigida.
