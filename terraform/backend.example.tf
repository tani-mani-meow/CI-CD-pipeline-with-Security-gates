terraform {
  backend "s3" {
    # After running scripts/bootstrap-state.sh, replace these values
    # with the actual S3 bucket and DynamoDB table created by the script.
    #
    #     region         = var.aws_region    # not supported in backend block
    #
    bucket         = "your-unique-bucket-name"     # created by bootstrap-state.sh
    key            = "cicd-pipeline/terraform.tfstate"
    region         = "us-east-1"                    # must match bootstrap region
    encrypt        = true
    dynamodb_table = "your-dynamodb-table-name"     # created by bootstrap-state.sh
  }
}
