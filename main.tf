locals {
  IMAGE_DEBIAN_11 = "debian-11-x64"
  SIZE_SMALL      = "s-1vcpu-1gb"
}

resource "digitalocean_ssh_key" "default" {
  name       = "default"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCslNKgLyoOrGDerz9pA4a4Mc+EquVzX52AkJZz+ecFCYZ4XQjcg2BK1P9xYfWzzl33fHow6pV/C6QC3Fgjw7txUeH7iQ5FjRVIlxiltfYJH4RvvtXcjqjk8uVDhEcw7bINVKVIS856Qn9jPwnHIhJtRJe9emE7YsJRmNSOtggYk/MaV2Ayx+9mcYnA/9SBy45FPHjMlxntoOkKqBThWE7Tjym44UNf44G8fd+kmNYzGw9T5IKpH1E1wMR+32QJBobX6d7k39jJe8lgHdsUYMbeJOFPKgbWlnx9VbkZh+seMSjhroTgniHjUl8wBFgw0YnhJ/90MgJJL4BToxu9PVnH ondrejsika"
}

resource "digitalocean_droplet" "example" {
  image  = local.IMAGE_DEBIAN_11
  name   = "example"
  region = "fra1"
  size   = local.SIZE_SMALL
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
}

output "ip" {
  value = digitalocean_droplet.example.ipv4_address
}
