variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nome globalmente único do bucket de Terraform state."
  type        = string
}
