variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "databases" {
  description = "Mapa de identificadores e nomes dos bancos PostgreSQL."
  type        = map(string)
}

variable "master_username" {
  type    = string
  default = "togglemaster_admin"
}

variable "instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
