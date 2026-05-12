terraform {
  backend "s3" {
    bucket         = "cicd-pipeline-terraform-state"
    key            = "cicd-pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cicd-pipeline-terraform-locks"
  }
}
