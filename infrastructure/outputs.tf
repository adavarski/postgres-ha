output "master_ip_address" {
  value = hcloud_server_network.postgres_master_network[*].ip
}

output "slave_ip_address" {
  value = hcloud_server_network.slave_network[*].ip
}

output "slave_ip_addresses" {
  value       = hcloud_server_network.slave_network[*].ip
  description = "The Slave IPs addresses for all nodes"
}
