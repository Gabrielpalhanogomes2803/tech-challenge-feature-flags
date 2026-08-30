variable "name_prefix" {
  type = string
}

variable "github_repository" {
  description = "Repositório autorizado no formato owner/repository."
  type        = string
}

variable "ecr_repository_arns" {
  description = "ARNs dos repositórios que o pipeline pode publicar."
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
