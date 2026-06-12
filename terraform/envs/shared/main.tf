# Shared VPC + single RDS instance; dev and prod use separate logical databases on this host.
#
# ⚠ COST TRADE-OFF: Dev and prod share one db.t4g.micro RDS instance to minimise cost (~$15/month).
# This is intentional for early-stage projects. Before going to production scale, split into
# separate RDS instances by moving the `module "rds"` block to envs/dev and envs/prod and
# removing it from this shared config.

data "aws_availability_zones" "available" {}

locals {
  project_name = "gabag-operations-platform"
  name_suffix  = "${local.project_name}-shared"

  common_tags = {
    Project     = local.project_name
    Environment = "shared"
    ManagedBy   = "Terraform"
  }

}

module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = "10.0.0.0/16"
  name_suffix        = local.name_suffix
  common_tags        = local.common_tags
  availability_zones = data.aws_availability_zones.available.names
}

module "rds" {
  source = "../../modules/rds"

  providers = {
    aws.backup_region = aws.backup_region
  }

  name_suffix             = local.name_suffix
  common_tags             = local.common_tags
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.public_subnet_ids
  allowed_security_groups = []
  allowed_cidr_blocks     = var.rds_allowed_cidr_blocks

  # Bootstrap DB only — app DBs created below via PostgreSQL provider
  db_name     = "postgres"
  db_username = var.db_username
  db_password = var.db_password

  publicly_accessible        = var.rds_publicly_accessible
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  max_allocated_storage      = var.rds_max_allocated_storage
  multi_az                   = var.rds_multi_az
  skip_final_snapshot        = var.rds_skip_final_snapshot
  deletion_protection        = var.rds_deletion_protection
  backup_retention_period    = var.rds_backup_retention_period
  enable_cross_region_backup = false
}

# App databases (gabag_dev, gabag_prod) are created by aws-setup.sh via psql
# after RDS is confirmed available. Using psql avoids the provider connection
# chicken-and-egg problem on first apply and on re-runs.
