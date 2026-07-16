terraform {
  backend "s3" {
    bucket       = "REPLACE_WITH_UNIQUE_S3_BUCKET"
    key          = "spring-petclinic/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

