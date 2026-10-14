locals {
  control_lxcs = {
    core = { # map key → becomes each.key in the resource
      vmid  = 100
      ip    = "192.168.8.100/24"
      mem   = 3072
      cores = 2
      disk  = 20
    }
    devops = {
      vmid  = 101
      ip    = "192.168.8.101/24"
      mem   = 4096 # Forgejo + Semaphore + Code-Server
      cores = 4
      disk  = 32 # Git repos + IDE projects + DBs
    }
    edge = {
      vmid  = 102
      ip    = "192.168.8.102/24"
      mem   = 1024
      cores = 2
      disk  = 8
    }
    # New LXC? Copy a block, bump vmid (= last IP octet), change ip/sizes.
  }
}

resource "proxmox_virtual_environment_container" "control" {
  for_each      = local.control_lxcs
  provider      = proxmox.control
  node_name     = "control"
  vm_id         = each.value.vmid
  unprivileged  = true
  start_on_boot = true

  cpu {
    cores = each.value.cores
  }
  memory {
    dedicated = each.value.mem
  }
  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk
  }
  operating_system {
    template_file_id = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
    type             = "debian"
  }

  dynamic "mount_point" {
    for_each = try(each.value.mounts, [])
    content {
      volume    = mount_point.value.volume
      path      = mount_point.value.path
      read_only = try(mount_point.value.read_only, false)
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = each.key
    #    hostname = "control-${each.key}"
    dns {
      servers = ["192.168.8.1", "1.1.1.1"]
    }
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.vmbr_gw
      }
    }
    user_account {
      password = data.sops_file.homelab_secrets.data["lxc_root_password"]
      keys     = [data.sops_file.homelab_secrets.data["ssh_public_key"]]
    }
  }

  features {
    nesting = true
    keyctl  = true
    fuse    = true
  }
}

output "control_container_ips" {
  value = {
    for k, v in local.control_lxcs : k => v.ip
  }
}
