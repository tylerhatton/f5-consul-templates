terraform {
  required_version = ">= 0.13.5"

  required_providers {
    bigip = {
      source  = "F5Networks/bigip"
      version = "1.11.1"
    }
  }
}