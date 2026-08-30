module "network" {
  source = "./modules/network"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  repository_names = [
    "togglemaster-auth",
    "togglemaster-flag",
    "togglemaster-targeting",
    "togglemaster-evaluation",
    "togglemaster-analytics"
  ]

  tags = local.common_tags
}

module "dynamodb" {
  source = "./modules/dynamodb"

  table_name = "ToggleMasterAnalytics"
  tags       = local.common_tags
}

module "sqs" {
  source = "./modules/sqs"

  queue_name = "togglemaster-analytics"
  tags       = local.common_tags
}

module "database" {
  source = "./modules/database"

  name_prefix        = local.name_prefix
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  databases = {
    auth      = "auth_db"
    flag      = "flags_db"
    targeting = "targeting_db"
  }

  tags = local.common_tags
}

module "redis" {
  source = "./modules/redis"

  name_prefix        = local.name_prefix
  vpc_id             = module.network.vpc_id
  vpc_cidr_block     = module.network.vpc_cidr_block
  private_subnet_ids = module.network.private_subnet_ids

  tags = local.common_tags
}

module "eks" {
  source = "./modules/eks"

  name_prefix         = local.name_prefix
  private_subnet_ids  = module.network.private_subnet_ids
  public_access_cidrs = var.eks_public_access_cidrs

  tags = local.common_tags
}

