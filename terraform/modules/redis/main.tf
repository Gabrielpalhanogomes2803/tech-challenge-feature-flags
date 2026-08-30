resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-redis-sg"
  description = "Acesso Redis interno da VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis a partir da VPC"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    description = "Trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis-sg"
  })
}

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Cache Redis do ToggleMaster"

  engine             = "redis"
  node_type          = var.node_type
  port               = 6379
  num_cache_clusters = 1

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.this.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = false

  automatic_failover_enabled = false
  multi_az_enabled           = false
  apply_immediately          = true

  snapshot_retention_limit = 1

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redis"
  })
}
