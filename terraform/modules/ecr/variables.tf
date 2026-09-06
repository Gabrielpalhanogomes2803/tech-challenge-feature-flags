variable "repository_names" {
  description = "Nomes dos repositórios ECR."
  type        = set(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
