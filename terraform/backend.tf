terraform {
  backend "s3" {
    bucket       = "petclinic-terraform-state-yugesh"
    key          = "spring-petclinic/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

