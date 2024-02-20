resource "null_resource" "PREVENT_DESTROY" {
  depends_on = [
    digitalocean_database_cluster.example,
  ]
}
