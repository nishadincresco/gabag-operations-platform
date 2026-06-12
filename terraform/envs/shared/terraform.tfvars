aws_region    = "eu-west-1"
backup_region = "eu-west-1"

dev_database_name  = "gabag_operations_platform_dev"
prod_database_name = "gabag_operations_platform_prod"

# db_password provided via TF_VAR_db_password (see scripts/aws-setup.sh)

rds_instance_class          = "db.t4g.micro"
rds_allocated_storage       = 20
rds_max_allocated_storage   = 50
rds_multi_az                = false
# ⚠ SECURITY: rds_publicly_accessible = true allows direct connections from
# outside the VPC (e.g. local dev machines). This is convenient for initial
# setup but should be set to false in production. When false, connect via
# EC2 Instance Connect endpoint or a VPN/bastion instead.
rds_publicly_accessible     = true
rds_backup_retention_period = 1
rds_deletion_protection     = false
rds_skip_final_snapshot     = true
