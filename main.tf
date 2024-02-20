locals {
  IMAGE_DEBIAN_11 = "debian-11-x64"
  IMAGE_DEBIAN_12 = "debian-12-x64"
  SIZE_SMALL      = "s-1vcpu-1gb"
  SIZE_MEDIUM     = "s-2vcpu-2gb"
}

resource "digitalocean_ssh_key" "default" {
  name       = "default"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCslNKgLyoOrGDerz9pA4a4Mc+EquVzX52AkJZz+ecFCYZ4XQjcg2BK1P9xYfWzzl33fHow6pV/C6QC3Fgjw7txUeH7iQ5FjRVIlxiltfYJH4RvvtXcjqjk8uVDhEcw7bINVKVIS856Qn9jPwnHIhJtRJe9emE7YsJRmNSOtggYk/MaV2Ayx+9mcYnA/9SBy45FPHjMlxntoOkKqBThWE7Tjym44UNf44G8fd+kmNYzGw9T5IKpH1E1wMR+32QJBobX6d7k39jJe8lgHdsUYMbeJOFPKgbWlnx9VbkZh+seMSjhroTgniHjUl8wBFgw0YnhJ/90MgJJL4BToxu9PVnH ondrejsika"
}

data "digitalocean_vpc" "default" {
  region = "fra1"
}

resource "digitalocean_droplet" "example" {
  image  = local.IMAGE_DEBIAN_11
  name   = "example"
  region = "fra1"
  size   = local.SIZE_MEDIUM
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
  vpc_uuid = data.digitalocean_vpc.default.id
}

output "ip" {
  value = digitalocean_droplet.example.ipv4_address
}

locals {
  db_prefix = "example"
  db_suffix = "pg"
  db_name   = "${local.db_prefix}-hello-${local.db_suffix}"
}

resource "digitalocean_database_cluster" "example" {
  name       = local.db_name
  engine     = "pg"
  version    = "15"
  size       = "db-s-1vcpu-2gb"
  region     = "fra1"
  node_count = 1
}

output "example_db_uri" {
  value     = digitalocean_database_cluster.example.uri
  sensitive = true
}


resource "digitalocean_vpc" "example" {
  for_each = {
    "1" = {
      suffix = "foo"
    }
    "3" = {
      suffix = "bar"
    }
  }

  name     = "example-${each.key + 1}-${each.value.suffix}"
  region   = "fra1"
  ip_range = "10.250.${each.key + 1}.0/24"
}

resource "digitalocean_droplet" "nginx" {
  image  = local.IMAGE_DEBIAN_11
  name   = "nginx"
  region = "fra1"
  size   = local.SIZE_MEDIUM
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
  connection {
    type  = "ssh"
    user  = "root"
    host  = self.ipv4_address
    agent = true
  }
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx",
    ]
  }
  provisioner "file" {
    content     = "<h1>Hello World from Terraform Provisioner!</h1>"
    destination = "/var/www/html/index.html"
  }
  vpc_uuid = data.digitalocean_vpc.default.id
}

output "nginx" {
  value = digitalocean_droplet.nginx.ipv4_address
}
