# ToggleMaster — Tech Challenge Fase 2

Plataforma distribuída para gerenciamento e avaliação de Feature Flags, desenvolvida como parte do Tech Challenge da Pós-Tech FIAP.

O projeto demonstra a conteinerização de microsserviços, a execução local com Docker Compose, a implantação em Kubernetes e a integração com serviços da AWS.

---

## Sobre o projeto

O ToggleMaster permite criar, consultar, configurar e avaliar Feature Flags de forma escalável.

A solução foi construída utilizando uma arquitetura de microsserviços, na qual cada serviço possui uma responsabilidade específica e pode ser implantado e escalado de maneira independente.

Entre os principais recursos estão:

- Criação e gerenciamento de Feature Flags;
- Autenticação por API Key;
- Definição de regras de segmentação;
- Avaliação de flags para usuários;
- Cache de avaliações;
- Publicação e processamento de eventos analíticos;
- Escalabilidade automática com Kubernetes HPA;
- Exposição externa por meio do NGINX Ingress.

---

## Arquitetura

O projeto é composto por cinco microsserviços:

| Microsserviço | Tecnologia | Responsabilidade | Dependência principal |
|---|---|---|---|
| `auth-service` | Go | Gerenciamento de API Keys e autenticação | PostgreSQL |
| `flag-service` | Python / Flask | CRUD das Feature Flags | PostgreSQL |
| `targeting-service` | Python / Flask | Gerenciamento de regras de segmentação | PostgreSQL |
| `evaluation-service` | Go | Avaliação das Feature Flags | Redis e Amazon SQS |
| `analytics-service` | Python | Consumo e armazenamento de eventos analíticos | Amazon SQS e DynamoDB |

### Fluxo simplificado

```text
Cliente
   |
   v
NGINX Ingress
   |
   +--> Auth Service ---------> PostgreSQL
   |
   +--> Flag Service ---------> PostgreSQL
   |
   +--> Targeting Service ----> PostgreSQL
   |
   +--> Evaluation Service ---> Redis
   |                         |
   |                         +--> Amazon SQS
   |
   +--> Analytics Service ----> Amazon SQS
                              |
                              +--> DynamoDB
```

---

## Tecnologias utilizadas

### Desenvolvimento

- Go
- Python
- Flask
- PostgreSQL
- Redis
- DynamoDB

### Conteinerização e orquestração

- Docker
- Docker Compose
- Kubernetes
- NGINX Ingress Controller
- Horizontal Pod Autoscaler
- Metrics Server

### AWS

- Amazon EKS
- Amazon ECR
- Amazon RDS for PostgreSQL
- Amazon ElastiCache for Redis
- Amazon DynamoDB
- Amazon SQS
- Elastic Load Balancing

### Automação

- GitHub Actions
- Shell Script
- AWS CLI
- kubectl
- eksctl

---

## Estrutura do projeto

O repositório contém os cinco microsserviços e três áreas principais:

- `.github/workflows/`: pipelines de CI e CD;
- `terraform/`: infraestrutura AWS e módulos reutilizáveis;
- `gitops/`: aplicações ArgoCD e manifests dos cinco serviços;
- `localstack/`: emulação local de SQS e DynamoDB;
- `docs/`: documentação de arquitetura, implantação e testes.

---

## Pré-requisitos

Para executar o projeto localmente, é necessário ter instalado:

- Git;
- Docker Desktop;
- Docker Compose.

Para realizar o deploy na AWS:

- AWS CLI;
- kubectl;
- eksctl;
- Conta AWS com permissões para ECR, EKS, EC2, RDS, ElastiCache, DynamoDB e SQS.

Verifique as ferramentas:

```bash
docker --version
docker compose version
aws --version
kubectl version --client
eksctl version
```

---

## Clonar o repositório

```bash
git clone https://github.com/Gabrielpalhanogomes2803/tech-challenge-feature-flags.git
```

Acesse a pasta:

```bash
cd tech-challenge-feature-flags
```

---

## Execução local

O ambiente local utiliza Docker Compose para iniciar os cinco microsserviços e suas dependências.

Suba todos os containers:

```bash
docker compose up --build -d
```

Verifique o status:

```bash
docker compose ps
```

O ambiente local deve possuir nove containers:

```text
auth-service
flag-service
targeting-service
evaluation-service
analytics-service
postgres-auth
postgres-main
redis
localstack
```

---

## Portas locais

| Serviço | Porta |
|---|---:|
| Auth Service | `8001` |
| Flag Service | `8002` |
| Targeting Service | `8003` |
| Evaluation Service | `8004` |
| Analytics Service | `8005` |
| LocalStack (SQS e DynamoDB) | `4566` (somente localhost) |
| PostgreSQL Auth | `5432` |
| PostgreSQL Main | `5433` |
| Redis | `6379` |

---

## Health checks

Após iniciar o ambiente, valide os microsserviços:

```bash
curl http://localhost:8001/health
curl http://localhost:8002/health
curl http://localhost:8003/health
curl http://localhost:8004/health
curl http://localhost:8005/health
```

Resultado esperado:

```json
{"status":"ok"}
```

---

## Logs

Visualizar os logs de todos os serviços:

```bash
docker compose logs -f
```

Visualizar os logs de um serviço específico:

```bash
docker compose logs -f auth-service
```

---

## Parar o ambiente local

Parar os containers:

```bash
docker compose stop
```

Parar e remover os containers:

```bash
docker compose down
```

Remover também os volumes locais:

```bash
docker compose down -v
```

> O uso da opção `-v` remove os dados armazenados nos bancos locais.

---

## Imagens Docker

As imagens dos microsserviços podem ser construídas individualmente:

```bash
docker build -t togglemaster-auth:local ./auth-service
docker build -t togglemaster-flag:local ./flag-service
docker build -t togglemaster-targeting:local ./targeting-service
docker build -t togglemaster-evaluation:local ./evaluation-service
docker build -t togglemaster-analytics:local ./analytics-service
```

Também está disponível o script:

```bash
./build-and-push.sh
```

Antes de utilizá-lo, revise as variáveis de região, conta AWS e nomes dos repositórios.

---

## Amazon ECR

O projeto utiliza cinco repositórios privados no Amazon ECR:

```text
togglemaster-auth
togglemaster-flag
togglemaster-targeting
togglemaster-evaluation
togglemaster-analytics
```

As imagens publicadas no ECR são utilizadas pelos Deployments do Kubernetes.

---

## Implantação no Kubernetes com GitOps

Os manifests estão em `gitops/services/`.

Depois que o CI DevSecOps é aprovado, o CD autentica na AWS usando GitHub OIDC, publica imagens no ECR com a tag do commit e atualiza o diretório GitOps. O ArgoCD detecta essa alteração e sincroniza o EKS automaticamente.

As cinco aplicações estão declaradas em `gitops/argocd/applications.yaml`.

Secrets preenchidos não são versionados. O formato esperado está em `gitops/runtime-secrets.example.yaml`.

---

## Validação do Kubernetes

Verifique os nós do cluster:

```bash
kubectl get nodes
```

Verifique os Pods:

```bash
kubectl get pods -n togglemaster
```

Verifique os Deployments:

```bash
kubectl get deployments -n togglemaster
```

Verifique os Services:

```bash
kubectl get services -n togglemaster
```

Verifique o Ingress:

```bash
kubectl get ingress -n togglemaster
```

Verifique os HPAs:

```bash
kubectl get hpa -n togglemaster
```

Visualize todos os recursos principais:

```bash
kubectl get all -n togglemaster
```

---

## Troubleshooting

Ver os logs de um Pod:

```bash
kubectl logs <NOME_DO_POD> -n togglemaster
```

Acompanhar os logs:

```bash
kubectl logs -f <NOME_DO_POD> -n togglemaster
```

Exibir detalhes e eventos:

```bash
kubectl describe pod <NOME_DO_POD> -n togglemaster
```

Listar os eventos do namespace:

```bash
kubectl get events -n togglemaster --sort-by='.lastTimestamp'
```

---

## Escalabilidade

O projeto utiliza Horizontal Pod Autoscaler para os serviços:

- `evaluation-service`;
- `analytics-service`.

O HPA realiza o ajuste automático da quantidade de réplicas conforme a utilização de CPU.

Verifique o status:

```bash
kubectl get hpa -n togglemaster
```

Para que as métricas sejam exibidas corretamente, o Metrics Server deve estar instalado no cluster.

---

## Testes realizados

Foram realizados testes relacionados a:

- Build das imagens Docker;
- Execução dos nove containers com Docker Compose;
- Health check dos cinco microsserviços;
- Comunicação entre microsserviços;
- Conexão com PostgreSQL;
- Uso do Redis;
- Publicação e consumo de mensagens;
- Armazenamento no DynamoDB;
- Aplicação de ConfigMaps e Secrets;
- Deployments e Services Kubernetes;
- Roteamento com NGINX Ingress;
- Escalabilidade com HPA;
- Execução dos serviços no Amazon EKS.

A documentação detalhada dos testes encontra-se em:

```text
docs/testes.md
```

---

## Documentação complementar

O repositório contém documentação adicional na pasta `docs`:

| Arquivo | Conteúdo |
|---|---|
| `docs/arquitetura.md` | Arquitetura da solução |
| `docs/deploy.md` | Procedimento de implantação |
| `docs/testes.md` | Testes e validações |
| `docs/apresentacao.md` | Roteiro para apresentação |
| `docs/cleanup.md` | Remoção dos recursos AWS |

Também existe um arquivo com comandos de validação:

```text
gitops/argocd/applications.yaml
```

---

## Segurança

Os arquivos de configuração do repositório utilizam apenas credenciais destinadas ao ambiente de desenvolvimento.

Credenciais reais da AWS, tokens, chaves privadas e arquivos `.env` não devem ser versionados.

Em ambientes produtivos, recomenda-se utilizar:

- EKS Pod Identity;
- AWS Secrets Manager;
- Kubernetes Secrets;
- Criptografia com AWS KMS;
- Política de menor privilégio;
- Rotação periódica de credenciais.

---

## Limpeza dos recursos AWS

Após os testes, remova os recursos para evitar cobranças desnecessárias.

Exemplo de remoção do cluster EKS:

```bash
eksctl delete cluster \
  --name togglemaster-cluster \
  --region us-east-1
```

Os demais recursos, como RDS, ElastiCache, Load Balancer, DynamoDB, SQS e ECR, também devem ser revisados e removidos quando não forem mais necessários.

Consulte:

```text
docs/cleanup.md
```

---

## Autores

Projeto desenvolvido por:

- Gabriel Palhano Gomes
- Heloísa Pereira Garcia
- Gustavo Ribeiro Borges
- Susana Sumire Nakasato
- João Victor Nunes de Moura

> Os RMs e usernames do Discord devem ser adicionados no relatório final de entrega.

---

## Repositório

```text
https://github.com/Gabrielpalhanogomes2803/tech-challenge-feature-flags
```

---

## Licença

Projeto desenvolvido para fins acadêmicos como parte do Tech Challenge da Pós-Tech FIAP.
