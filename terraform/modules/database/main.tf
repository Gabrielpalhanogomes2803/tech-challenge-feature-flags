resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-database-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-subnets"
  })
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Acesso PostgreSQL interno da VPC"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL a partir da VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
}

resource "aws_db_instance" "this" {
  for_each = var.databases

  identifier = "${var.name_prefix}-${each.key}"

  engine         = "postgres"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = each.value
  username = var.master_username

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  publicly_accessible     = false
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 7

  auto_minor_version_upgrade = true
  apply_immediately          = true

  tags = merge(var.tags, {
    Name    = "${var.name_prefix}-${each.key}"
    Service = each.key
  })
}
