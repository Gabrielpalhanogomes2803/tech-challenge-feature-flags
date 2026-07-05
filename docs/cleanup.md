# Limpeza do Ambiente AWS

Após a conclusão do projeto todos os recursos foram removidos para evitar custos.

## Recursos removidos

- Amazon EKS
- Node Groups
- Amazon ECR
- Amazon ElastiCache Redis
- Amazon RDS
- Amazon DynamoDB
- Amazon SQS
- Load Balancer
- VPC criada para o projeto
- Security Groups
- Internet Gateway
- Subnets
- Route Tables

---

## Verificações realizadas

```bash
aws eks list-clusters

aws ecr describe-repositories

aws rds describe-db-instances

aws elasticache describe-cache-clusters

aws dynamodb list-tables

aws sqs list-queues

aws ec2 describe-vpcs
```

Resultado:

Todos os recursos específicos do projeto foram removidos.

Apenas a VPC padrão da conta AWS permaneceu ativa.


