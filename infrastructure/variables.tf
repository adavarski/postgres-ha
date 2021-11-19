variable "hcloud_token" {
  default = ""
}

variable "os_image" {
  default = "ubuntu-20.04"
}

variable "instance_type" {
  default = "cpx11"
}

variable "master_node_count" {
  default = "1"
}

variable "slave_node_count" {
  default = "2"
}

variable "multi_master" {
  default = false
}

variable "server_locations" {
  description = "Server locations in which servers will be distributed"
#  default     = ["nbg1", "fsn1", "hel1"]
  default     = ["hel1"]
  type        = list(string)
}
