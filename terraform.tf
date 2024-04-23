terraform {
  required_version = ">= 1.3.2"

  required_providers {  
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.7.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.4"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
  }
}