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

resource "digitalocean_ssh_key" "default-ecdsa" {
  name       = "default-ecdsa"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHtI4BsjxWHmRB3EzyQDSX5idgyjD67XL4WmIjz+pcG6 ondrej@sika-mac"
}


data "digitalocean_vpc" "default" {
  region = "fra1"
}

resource "digitalocean_droplet" "example" {
  lifecycle {
    ignore_changes = [
      ssh_keys,
    ]
  }

  image  = local.IMAGE_DEBIAN_11
  name   = "example"
  region = "fra1"
  size   = local.SIZE_MEDIUM
  ssh_keys = [
    digitalocean_ssh_key.default.id,
    digitalocean_ssh_key.default-ecdsa.id,
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
  lifecycle {
    prevent_destroy = true
  }

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

resource "digitalocean_droplet" "nginx2" {
  image  = local.IMAGE_DEBIAN_11
  name   = "nginx2"
  region = "fra1"
  size   = local.SIZE_MEDIUM
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
  vpc_uuid  = data.digitalocean_vpc.default.id
  user_data = <<EOF
#cloud-config
ssh_pwauth: yes
password: asdfasdf2020
chpasswd:
  expire: false
write_files:
- path: /html/index.html
  permissions: "0755"
  owner: root:root
  content: |
    <h1>Hello from Cloud Init
runcmd:
  - |
    apt update
    apt install -y curl sudo git nginx
    curl -fsSL https://ins.oxs.cz/slu-linux-amd64.sh | sudo sh
    cp /html/index.html /var/www/html/index.html
EOF
}

output "nginx2" {
  value = digitalocean_droplet.nginx2.ipv4_address
}


resource "digitalocean_vpc" "foo" {
  name        = "example-foo"
  region      = "fra1"
  ip_range    = "10.200.1.0/24"
  description = "created-at=${timestamp()}"

  lifecycle {
    ignore_changes = [
      description,
    ]
  }
}

output "vpc_foo_desc" {
  value = digitalocean_vpc.foo.description
}

resource "digitalocean_domain" "default" {
  name = "do-2024-02-20-0.sikademo.com"
}

resource "digitalocean_record" "nginx2" {
  domain = digitalocean_domain.default.id
  type   = "A"
  name   = "nginx2"
  value  = digitalocean_droplet.nginx2.ipv4_address
}

output "see" {
  value = "http://${digitalocean_record.nginx2.fqdn}"
}

locals {
  ssh_keys = [
    digitalocean_ssh_key.default.id,
  ]
  vms = {
    foo = {}
    bar = {}
  }
}

module "vm" {
  for_each = local.vms

  source = "./modules/vm"

  name      = each.key
  ssh_keys  = local.ssh_keys
  domain_id = digitalocean_domain.default.id
}

output "fqdns" {
  value = {
    for k, v in module.vm :
    k => module.vm[k].fqdn
  }
}

output "price" {
  value = module.vm["bar"].droplet.price_monthly
}
