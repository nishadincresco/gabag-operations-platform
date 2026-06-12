resource "aws_db_subnet_group" "main" {
  name       = "${var.name_suffix}-db-public-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_suffix}-db-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.name_suffix}-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    cidr_blocks     = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_suffix}-rds-sg"
  })
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.name_suffix}-db-v2"
  engine            = "postgres"
  engine_version    = "16" # Minor version managed automatically
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  # Enable storage autoscaling when max_allocated_storage > 0
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null

  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = var.multi_az
  skip_final_snapshot = var.skip_final_snapshot
  deletion_protection = var.deletion_protection

  auto_minor_version_upgrade = true
  backup_retention_period    = var.backup_retention_period
  backup_window              = "03:00-04:00"
  maintenance_window         = "Mon:04:00-Mon:05:00"

  publicly_accessible = var.publicly_accessible
  storage_encrypted   = true

  tags = merge(var.common_tags, {
    Name = "${var.name_suffix}-db"
  })
}

resource "aws_db_instance_automated_backups_replication" "cross_region" {
  count    = var.enable_cross_region_backup ? 1 : 0
  provider = aws.backup_region

  source_db_instance_arn = aws_db_instance.postgres.arn
  retention_period       = 7
}
