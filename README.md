# ToggleMaster | Feature Flags, GitOps e Observabilidade

**FIAP Pós-Tech · Tech Challenge · Fases 3 e 4**

Plataforma de gerenciamento e avaliação de *feature flags* com cinco microsserviços, infraestrutura AWS provisionada por Terraform, entrega contínua via GitHub Actions/ECR/Argo CD e observabilidade no Amazon EKS.

> **Estado da última vistoria — 23/10/2026:** 11 aplicações Argo CD `Synced/Healthy`; 2 nós monitorados; 5 microsserviços com 10/10 réplicas; Grafana **Operations Center V9** (37 elementos); logs dos cinco serviços consultáveis no Loki; 5/5 sondagens HTTP saudáveis, com resposta 200. São evidências pontuais, não garantia de disponibilidade permanente.

## Arquitetura e fluxo

```text
GitHub Actions (CI/DevSecOps) -> ECR -> GitOps/Argo CD -> EKS
                                                       |
                         +-----------------------------+---------------------+
                         |                             |                     |
                  5 microsserviços              Prometheus + Blackbox    Alloy -> Loki
                         |                             |                     |
                  PostgreSQL/Redis/SQS/DynamoDB       +---------- Grafana <-+
```

**Serviços:** `auth` (Go), `flag` (Python/Flask), `targeting` (Python/Flask), `evaluation` (Go) e `analytics` (Python).

**Observabilidade Fase 4:** Prometheus coleta métricas de cluster/serviços; Blackbox Exporter verifica os endpoints `/health`; Alloy encaminha logs do Kubernetes para Loki; Grafana centraliza saúde, réplicas, CPU/RAM, tendências, logs, erros e latência HTTP. O dashboard é versionado em `gitops/monitoring/grafana/dashboards/eks-dashboard-configmap.yaml` e implantado via Argo CD.

## Evidências e documentação

- [Vistoria técnica de observabilidade — 23/10/2026](docs/observabilidade-vistoria-2026-10-23.md)
- [Passagem técnica para João — OpenTelemetry](docs/handoff-joao-opentelemetry.md)
- [Limpeza e verificação de recursos AWS](docs/cleanup.md)
- [Arquitetura](docs/arquitetura.md)

## Acesso e verificação rápida

O serviço Grafana é `ClusterIP`, sem URL pública permanente. Com acesso autorizado ao cluster, executar localmente:

```bash
kubectl -n argocd get applications
kubectl -n monitoring get pods,pvc
kubectl -n monitoring port-forward svc/togglemaster-grafana 3001:80
```

Abrir `http://localhost:3001` **na máquina que executa o comando**, usando credenciais existentes; não publicar credenciais ou expor a interface à internet. Dashboard: **Dashboards → ToggleMaster → ToggleMaster | Operations Center**. No CloudShell, a prévia web pode ter restrições de porta.

## Pendências e limites conhecidos

- A janela de 15 minutos apresentou `JSONParserErr` em algumas linhas do Loki; investigar a consulta LogQL e a formatação mista de logs antes de tratar essas entradas como falhas da aplicação.
- Há avisos de servidor de desenvolvimento em logs de serviços Python; revisar a execução para uso fora do laboratório.
- Ainda são necessários testes de carga e validação de alertas, tracing/APM e self-healing pelos responsáveis.
- OpenTelemetry Collector (João): alinhar a topologia com o Alloy para **não duplicar a ingestão de logs**.
- As evidências descrevem um instante de execução. O ambiente pode ser desligado após a demonstração; o GitHub não comprova que a AWS permanece ligada.

## Encerramento seguro da AWS

**Não executar destroy enquanto outros integrantes estiverem usando o EKS, os bancos, Redis, SQS ou outros recursos.** Após aprovação da equipe, conferir conta/região, backend/state e plano de destruição; o script `scripts/aws/09-destroy.sh` exige digitar `DESTROY` e aplica `terraform plan -destroy`. O script preserva o bucket de state e o orçamento AWS; recursos fora do state precisam de verificação separada. Não versionar state, credenciais ou segredos.

---

## Histórico técnico — Fase 3

O conteúdo abaixo preserva os detalhes originais de CI/CD, Terraform, EKS e segurança da Fase 3.

ToggleMaster — Tech Challenge Fase 3

Plataforma distribuída para gerenciamento e avaliação de Feature Flags, desenvolvida como parte do Tech Challenge — Fase 3 da Pós-Tech FIAP.

Nesta fase, o projeto evoluiu para um fluxo completo de Infraestrutura como Código, CI/DevSecOps, publicação de imagens no Amazon ECR e entrega GitOps com ArgoCD no Amazon EKS.

Observação: os recursos AWS são provisionados sob demanda para demonstração e testes. Após a validação final, a infraestrutura pode ser destruída para evitar cobranças. O repositório mantém todo o código necessário para recriação do ambiente.

Visão geral

O ToggleMaster é composto por cinco microsserviços independentes:

Microsserviço

Tecnologia

Responsabilidade

Dependência principal

auth-service

Go

Gerenciamento de API Keys e autenticação

PostgreSQL

flag-service

Python / Flask

CRUD de Feature Flags

PostgreSQL

targeting-service

Python / Flask

Regras de segmentação

PostgreSQL

evaluation-service

Go

Avaliação das Feature Flags

Redis e Amazon SQS

analytics-service

Python

Processamento de eventos analíticos

Amazon SQS e DynamoDB

Fluxo de entrega da Fase 3:

Código
  |
  v
GitHub Actions - CI / DevSecOps
  |  testes + lint + SAST + SCA + container scan
  v
GitHub Actions - CD
  |  build + push de imagens com tag SHA
  v
Amazon ECR
  |
  v
Atualização automática dos manifests GitOps
  |
  v
ArgoCD
  |
  v
Amazon EKS

Infraestrutura AWS com Terraform

A infraestrutura é definida em terraform/ e organizada em módulos reutilizáveis.

Principais recursos provisionados:

VPC;

subnets públicas e privadas;

Internet Gateway;

Route Tables;

Amazon EKS;

EKS Node Group;

três instâncias Amazon RDS PostgreSQL;

Amazon ElastiCache for Redis;

tabela DynamoDB ToggleMasterAnalytics;

fila Amazon SQS;

cinco repositórios Amazon ECR;

políticas e permissões necessárias para execução dos serviços.

O estado do Terraform utiliza backend remoto em Amazon S3. O bucket de state é criado separadamente pelo bootstrap localizado em:

terraform/bootstrap/

O bootstrap habilita:

versionamento;

criptografia AES-256;

bloqueio de acesso público.

CI / DevSecOps

O workflow principal está em:

.github/workflows/ci.yml

Ele é executado em Pull Requests para main, pushes em main / fase-3 e também pode ser acionado manualmente.

Controles executados:

Serviços Go

download das dependências;

testes unitários;

go vet;

SAST com Gosec.

Serviços Python

instalação e validação das dependências;

syntax check;

lint com Flake8;

SAST com Bandit.

Segurança do repositório

SCA com Trivy:

scan-type: fs
scanners: vuln, secret, misconfig
severity: CRITICAL
exit-code: 1

Segurança das imagens

Cada microsserviço é construído com a tag do SHA do commit e analisado com Trivy.

Uma vulnerabilidade CRITICAL faz o job falhar e bloqueia a pipeline.

Evidência do security gate

Foi realizada uma demonstração controlada inserindo propositalmente uma dependência vulnerável no analytics-service.

Commit da demonstração:

cde129a  test: demonstrate vulnerable dependency blocking CI

A dependência introduzida foi:

Django==3.0.0

O Trivy identificou vulnerabilidades CRITICAL e a pipeline retornou exit code 1.

A correção foi registrada em:

52a355c  fix: remove vulnerable Django dependency

Após a remoção da dependência vulnerável, os mesmos controles foram executados novamente e a pipeline foi aprovada.

CD, ECR e imagens imutáveis

O workflow de entrega está em:

.github/workflows/main.yml

O CD é executado após a conclusão bem-sucedida do CI na main.

Fluxo:

resolve o SHA do commit aprovado;

faz checkout do commit;

autentica na AWS via GitHub OIDC;

realiza login no Amazon ECR;

constrói as cinco imagens;

publica as imagens com tag baseada no SHA;

atualiza os cinco deployment.yaml;

cria um commit GitOps automático;

envia a alteração para a main.

Exemplo de tag:

<registry>/togglemaster-auth:<commit-sha>

Não é utilizado latest no fluxo de entrega.

GitOps e ArgoCD

Os manifests Kubernetes ficam em:

gitops/

Estrutura principal:

gitops/
├── argocd/
├── services/
│   ├── auth/
│   ├── flag/
│   ├── targeting/
│   ├── evaluation/
│   └── analytics/
├── namespace.yaml
└── runtime-secrets.example.yaml

Cada serviço possui manifests de Deployment, Service e Kustomize.

As cinco Applications do ArgoCD estão declaradas em:

gitops/argocd/applications.yaml

O ArgoCD monitora o repositório e sincroniza automaticamente as alterações com o EKS.

Na validação final da demonstração, as cinco aplicações ficaram Synced e Healthy, com os cinco microsserviços em execução no cluster.

Estrutura do repositório

.github/workflows/   CI DevSecOps e CD
analytics-service/   Serviço de analytics
auth-service/        Serviço de autenticação
evaluation-service/  Serviço de avaliação
flag-service/        Serviço de flags
targeting-service/   Serviço de targeting
terraform/           Infraestrutura AWS
terraform/bootstrap/ Bootstrap do backend remoto
gitops/              Manifests Kubernetes e ArgoCD
scripts/aws/         Automação do ciclo de vida AWS
localstack/          Recursos locais para SQS/DynamoDB
docs/                Documentação complementar

Execução local

Para o ambiente local:

docker compose up --build -d

Verifique os containers:

docker compose ps

Health checks:

curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health

Resultado esperado: `"status": "ok"` em todos. O `/health` checa a dependência
real de cada serviço (PostgreSQL, Redis ou DynamoDB/SQS) e retorna `503` com
`"status": "degraded"` quando ela está fora. O `/live` só indica que o processo
está de pé e é usado como liveness probe no Kubernetes.

Para remover o ambiente local:

docker compose down

Pré-requisitos para AWS

Git;

Docker;

AWS CLI;

kubectl;

conta AWS com as permissões necessárias.

O Terraform utilizado pelos scripts AWS é executado dentro de container Docker, por meio das funções presentes em scripts/aws/common.sh.

Automação do ambiente AWS

Os scripts principais estão em scripts/aws/:

Script

Função

01-login.sh

valida / inicia a autenticação AWS

02-provision.sh

executa init, fmt, validate, plan e apply do Terraform

03-status.sh

consulta o estado dos principais recursos AWS

03-sync-gitops.sh

sincroniza endpoints de runtime e GitOps

04-open-eks.sh

libera temporariamente o endpoint do EKS para o IP autorizado

05-bootstrap-cluster.sh

configura runtime, bancos, ArgoCD e aplicações

06-validate.sh

valida EKS, ArgoCD, deployments e health checks

07-argocd-access.sh

fornece acesso local ao ArgoCD

08-close-eks.sh

fecha o acesso público temporário ao EKS

09-destroy.sh

destrói a infraestrutura principal

Provisionamento

Com o backend remoto previamente configurado:

cd ~/tech-challenge-feature-flags
./scripts/aws/01-login.sh
./scripts/aws/02-provision.sh

Depois do provisionamento e da publicação das imagens:

./scripts/aws/04-open-eks.sh
./scripts/aws/05-bootstrap-cluster.sh
./scripts/aws/06-validate.sh

Validação final

O script:

./scripts/aws/06-validate.sh

verifica:

node do EKS;

cinco Applications do ArgoCD;

estado Synced;

estado Healthy;

cinco Deployments;

rollout dos microsserviços;

health check dos cinco serviços;

acesso ao DynamoDB.

Resultado esperado:

VALIDAÇÃO CONCLUÍDA COM SUCESSO.

Limpeza dos recursos AWS

Para evitar cobranças após testes ou demonstrações:

cd ~/tech-challenge-feature-flags
./scripts/aws/09-destroy.sh

O script exige confirmação explícita:

DESTROY

O 09-destroy.sh remove a infraestrutura principal gerenciada pelo Terraform e preserva, por segurança, o backend S3 e o orçamento AWS.

Caso seja necessário encerrar definitivamente o ambiente, o bucket de state e o orçamento também devem ser revisados e removidos manualmente depois que não forem mais necessários.

A exclusão do bucket de state impede que o ambiente seja recriado sem antes executar novamente o bootstrap do backend.

Segurança

O projeto adota:

SAST com Gosec e Bandit;

SCA com Trivy;

container scanning com Trivy;

bloqueio para vulnerabilidades CRITICAL;

GitHub OIDC para autenticação do CD na AWS;

imagens versionadas por SHA;

Secrets fora do Git;

credenciais de banco recuperadas em runtime;

acesso público ao EKS restrito temporariamente por CIDR;

backend Terraform com versionamento, criptografia e bloqueio público.

Nunca devem ser versionados Access Keys, tokens, senhas, arquivos .env com credenciais, states locais contendo dados sensíveis ou Secrets Kubernetes preenchidos.

Evidências principais da Fase 3

cde129a  demonstração de dependência vulnerável
52a355c  correção da vulnerabilidade
cd6b9d2  merge da demonstração de segurança
ba7dd6b  redeploy do ambiente AWS para validação final
e2a6209  commit GitOps automático da entrega final

Fluxo final validado:

Terraform
   ↓
AWS
   ↓
CI / DevSecOps
   ↓
ECR
   ↓
GitOps
   ↓
ArgoCD
   ↓
EKS

Autores

Gabriel Palhano Gomes

Heloísa Pereira Garcia

Gustavo Ribeiro Borges

Susana Sumire Nakasato

João Victor Nunes de Moura

Repositório

https://github.com/Gabrielpalhanogomes2803/tech-challenge-feature-flags

Projeto acadêmico desenvolvido para o Tech Challenge — Fase 3 da Pós-Tech FIAP.
