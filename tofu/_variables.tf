variable "vmbr_gw" {
  type    = string
  default = "192.168.8.1"
}

variable "vmbr_cidr" {
  type    = string
  default = "192.168.8.0/24"
}

# Keep your existing vars
variable "devops_ip" { default = "192.168.8.101" }
variable "code_server_port" { default = "8080" }
variable "forgejo_port" { default = "3000" }
variable "semaphore_port" { default = "3001" }
variable "termix_port" { default = "8081" }
