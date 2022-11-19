terraform {
  backend "s3" {
    bucket = "onlyselfsigned.org-tfstate"
    key    = "onlyselfsigned.org.tfstate"
    region = "eu-west-2"
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"

  default_tags {
    tags = local.default_tags
  }
}
