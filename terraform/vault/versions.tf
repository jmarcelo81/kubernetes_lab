terraform {
  required_version = ">= 1.6"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# REMEMBER: Address + token come from the environment, never from code:
provider "vault" {}
