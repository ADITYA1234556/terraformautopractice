terraform {
  backend "s3" {
    bucket         = "111-aditya-kms"
    key            = "terraform/terraform.tfstate"
    region         =  var.REGION["london"]
  }
}
