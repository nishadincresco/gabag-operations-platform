terraform {
  backend "s3" {
    bucket         = "gabag-operations-platform-tf-state"
    key            = "shared/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "gabag-operations-platform-terraform-locks"
  }
}
