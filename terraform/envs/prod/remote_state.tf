data "terraform_remote_state" "shared" {
  backend = "s3"

  config = {
    bucket = "gabag-operations-platform-tf-state"
    key    = "shared/terraform.tfstate"
    region = "eu-west-1"
  }
}
