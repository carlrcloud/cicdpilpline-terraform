terraform {
  backend "s3" {
    bucket  = "cicd-terraform-carlos58"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}