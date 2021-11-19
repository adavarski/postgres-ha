resource "random_string" "random" {
  length           = 16
  special          = true
  override_special = "/@£$"
}
resource "hcloud_network" "postgres_network" {
  name     = join("-",["hetzner-postgres", random_string.random.id])
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "subnet_pub" {
  network_id   = hcloud_network.postgres_network.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_server_network" "postgres_master_network" {
  count      = var.master_node_count
  server_id  = hcloud_server.kube_master[count.index].id
  network_id = hcloud_network.postgres_network.id
}

resource "hcloud_server_network" "slave_network" {
  count      = var.slave_node_count
  server_id  = hcloud_server.slave[count.index].id
  network_id = hcloud_network.postgres_network.id
}
