variable "name_prefix" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_access_cidrs" {
  description = "CIDRs autorizados a acessar publicamente a API do EKS."
  type        = list(string)
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
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
