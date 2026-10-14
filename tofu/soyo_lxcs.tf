# soyo LXC - PHASE 04 watch
# Node: soyo (192.168.8.12) - N150 16GB
# LXC scheme: 120-139 = soyo range (20 * 10 + offset)
# Verify on soyo node:
# 1. datastore = local-lvm (check pve storage.cfg)
# 2. template local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst downloaded
# 3. subuid mapping for unprivileged containers

locals {
  soyo_lxcs = {
    watch = {
      vmid     = 120
      hostname = "watch"
      ip       = "192.168.8.120/24"
      mem      = 2048        # 2GB more than enough - see sizing below
      cores    = 2
      disk     = 16
      # No mount needed for watch - stateless-ish, volumes in local-lvm
    }
    # Future:
    # dl-qbt = { vmid=121 ip=192.168.8.121/24 mem=4096 cores=2 disk=16 mount={volume=/dev/sdb path=/mnt/qbt1} }
  }
}

resource "proxmox_virtual_environment_container" "soyo" {
  for_each      = local.soyo_lxcs
  provider      = proxmox.soyo
  node_name     = "soyo"
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

  # For qbt ext4 pass-through you will need mp0: /dev/sdb,mp=/mnt/qbt1 later
  # Use custom mount for now if needed:
  # mount_point { volume = "/dev/sdb" path = "/mnt/qbt1" }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = each.key
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

output "soyo_container_ips" {
  value = { for k, v in local.soyo_lxcs : k => v.ip }
}
