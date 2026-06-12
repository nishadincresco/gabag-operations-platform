terraform {
  backend "s3" {
    # TODO: Create this S3 bucket + DynamoDB table before running terraform init.
    # Run: aws s3 mb s3://gabag-operations-platform-tf-state --region eu-west-1
    # Run: aws dynamodb create-table --table-name gabag-operations-platform-terraform-locks \
    #        --attribute-definitions AttributeName=LockID,AttributeType=S \
    #        --key-schema AttributeName=LockID,KeyType=HASH \
    #        --billing-mode PAY_PER_REQUEST --region eu-west-1
    bucket         = "gabag-operations-platform-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "gabag-operations-platform-terraform-locks"
  }
}
