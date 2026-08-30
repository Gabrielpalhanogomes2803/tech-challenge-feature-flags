locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = "ToggleMaster"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "tech-challenge-feature-flags"
  }
}
