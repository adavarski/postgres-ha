resource "hcloud_server" "slave" {
  count       = var.slave_node_count
  name        = format("slave%03d", count.index + 1)
  image       = var.os_image
  server_type = var.instance_type
  ssh_keys    = [hcloud_ssh_key.this.name]
  location    = var.server_locations[0]
}
