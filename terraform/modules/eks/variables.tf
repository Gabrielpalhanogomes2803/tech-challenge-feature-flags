variable "name_prefix" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3a.large"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "sqs_queue_arn" {
  description = "ARN da fila utilizada pelos workloads."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN da tabela utilizada pelo analytics-service."
  type        = string
}
variable "eks_public_access_cidrs" {
  description = "CIDRs autorizados a acessar a API publica do EKS"
  type        = list(string)
  default     = []
}
