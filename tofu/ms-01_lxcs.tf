# Allocated (VMID == last IP octet): 178 samba, 161 seafile
locals {
  ms01_lxcs = {
    samba = {
      vmid  = 178
      ip    = "192.168.8.178/24"
      mem   = 2048
      cores = 1
      disk  = 8 # small rootfs on NVMe

      mounts = [
        { volume = "/tank", path = "/mnt/tank" },
      ]
    }
    seafile = {
      vmid  = 161
      ip    = "192.168.8.161/24"
      mem   = 4096
      cores = 4
      disk  = 20

      mounts = [
        { volume = "/tank/seafile/data", path = "/mnt/seafile-data" },
        { volume = "/tank/seafile/mysql", path = "/mnt/seafile-mysql" },
        { volume = "/tank/seafile/conf", path = "/mnt/seafile-conf" },
        { volume = "/tank/seafile/seahub-data", path = "/mnt/seafile-seahub-data" },
        { volume = "/tank/seafile/seadoc-data", path = "/mnt/seadoc-data" },
        { volume = "/tank/media", path = "/mnt/media", read_only = true },
        { volume = "/tank/paperless", path = "/mnt/paperless" },
        { volume = "/tank/paperless/consume-transit", path = "/mnt/paperless-transit" },
      ]
    }
    # New LXC? Copy a block. Omit `mounts` entirely for containers that shouldn't see /tank.
  }
}

resource "proxmox_virtual_environment_container" "ms01" {
  for_each      = local.ms01_lxcs
  provider      = proxmox.ms01
  node_name     = "ms-01"
  vm_id         = each.value.vmid
  unprivileged  = true
  start_on_boot = true

  cpu { cores = each.value.cores }
  memory { dedicated = each.value.mem }

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
    #    hostname = "ms01-${each.key}" # ← was "control-..." (copy-paste bug)
    hostname = each.key
    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
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

output "ms01_container_ips" {
  value = {
    for k, v in local.ms01_lxcs : k => v.ip
  }
}
