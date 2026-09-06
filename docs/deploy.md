# Implantação do ToggleMaster

## Fluxo

1. Terraform provisiona a infraestrutura AWS.
2. GitHub Actions executa CI e verificações DevSecOps.
3. O CD publica imagens imutáveis no ECR.
4. ArgoCD sincroniza os manifests GitOps no EKS.

## Ambiente local

```bash
docker compose up -d
docker compose ps
```

Health checks:

```bash
for port in 8001 8002 8003 8004 8005; do
  curl -fsS "http://localhost:${port}/health"
  echo
done
```

Encerrar:

```bash
docker compose down
```

## Terraform

Validação sem criar recursos:

```bash
cd terraform
terraform fmt -recursive -check
terraform init -backend=false
terraform validate
```

O backend remoto deve ser configurado a partir de `backend.hcl.example`. O arquivo preenchido não deve ser versionado.

Antes do provisionamento, copie `terraform.tfvars.example` para `terraform.tfvars`, revise o plano e somente então execute o apply autorizado.

## Recursos AWS

- VPC, subnets, Internet Gateway, NAT Gateway e rotas;
- EKS e Managed Node Group;
- três RDS PostgreSQL;
- ElastiCache Redis;
- DynamoDB, SQS e DLQ;
- cinco repositórios ECR;
- GitHub OIDC e EKS Pod Identity.

## Secrets

O GitHub usa OIDC e assume a role indicada pelo secret `AWS_DEPLOY_ROLE_ARN`. Access Keys permanentes não são necessárias.

Os secrets das aplicações devem ser criados por mecanismo externo seguro. `gitops/runtime-secrets.example.yaml` contém somente o formato esperado.

## ArgoCD

Após o cluster e o ArgoCD estarem disponíveis:

```bash
kubectl apply -f gitops/namespace.yaml
kubectl apply -f gitops/argocd/applications.yaml
```

Validação:

```bash
kubectl get applications -n argocd
kubectl get pods -n togglemaster
kubectl get deployments -n togglemaster
kubectl get services -n togglemaster
```

O resultado esperado para as aplicações é `Synced` e `Healthy`.

## Pipeline

O CI executa testes, lint, Gosec, Bandit, Trivy filesystem, build das cinco imagens e Trivy container scan. Após aprovação na branch `main`, o CD publica as imagens usando o SHA do commit e atualiza o GitOps.
