variable "aws_region" {
  description = "Região AWS utilizada pelo projeto."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto usado na identificação dos recursos."
  type        = string
  default     = "togglemaster"
}

variable "environment" {
  description = "Ambiente provisionado."
  type        = string
  default     = "homolog"
}

variable "vpc_cidr" {
  description = "Bloco CIDR principal da VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Zonas de disponibilidade usadas pela infraestrutura."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs das subnets públicas."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDRs das subnets privadas."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]
}

variable "eks_public_access_cidrs" {
  description = "CIDRs autorizados a acessar a API pública do EKS."
  type        = list(string)

  validation {
    condition     = length(var.eks_public_access_cidrs) > 0
    error_message = "Informe ao menos um CIDR autorizado para acessar o EKS."
  }
}
