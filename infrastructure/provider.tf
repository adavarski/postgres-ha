provider "hcloud" {
  token = var.hcloud_token
}

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.25.1"
    }
  }
  required_version = ">= 0.12"
}
