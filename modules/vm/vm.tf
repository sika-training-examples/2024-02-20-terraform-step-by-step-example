terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.34.1"
    }
  }
}

variable "name" {
  description = "The name of the droplet"
  type        = string
}

variable "image" {
  description = "The image to use for the droplet"
  default     = "debian-12-x64"
  type        = string
}

variable "size" {
  description = "The size of the droplet"
  default     = "s-1vcpu-1gb"
  type        = string
}

variable "ssh_keys" {
  description = "The SSH keys to use for the droplet"
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID to use for the droplet"
  type        = string
  default     = null
}

variable "domain_id" {
  description = "The domain to use for the droplet"
  type        = string
}

resource "digitalocean_droplet" "this" {
  image    = var.image
  name     = var.name
  region   = "fra1"
  size     = var.size
  ssh_keys = var.ssh_keys
  vpc_uuid = var.vpc_id
}

resource "digitalocean_record" "this" {
  domain = var.domain_id
  type   = "A"
  name   = digitalocean_droplet.this.name
  value  = digitalocean_droplet.this.ipv4_address
}

output "droplet" {
  value = digitalocean_droplet.this
}

output "record" {
  value = digitalocean_record.this
}

output "fqdn" {
  value = digitalocean_record.this.fqdn
}
