terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.65.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "= 2026.8.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }
}

# bpg/proxmox endpoint must be https://IP:8006 - NO /api2/json suffix
provider "proxmox" {
  alias    = "control"
  endpoint = data.sops_file.homelab_secrets.data["pve_control_api_url"]
  username = "root@pam"
  password = data.sops_file.homelab_secrets.data["pve_root_password"]
  insecure = true
}

provider "proxmox" {
  alias    = "ms01"
  endpoint = data.sops_file.homelab_secrets.data["pve_ms01_api_url"]
  username = "root@pam"
  password = data.sops_file.homelab_secrets.data["pve_root_password"]
  insecure = true
}

provider "proxmox" {
  alias    = "soyo"
  endpoint = data.sops_file.homelab_secrets.data["pve_soyo_api_url"]
  username = "root@pam"
  password = data.sops_file.homelab_secrets.data["pve_root_password"]
  insecure = true
}

provider "authentik" {
  url   = "https://auth.h-and-i.com"
  token = data.sops_file.core_secrets.data["AUTHENTIK_BOOTSTRAP_TOKEN"]
}

provider "uptimekuma" {
  alias = "kuma"
  url   = "https://uptime.h-and-i.com"
  username = data.sops_file.watch_secrets.data["UPTIME_KUMA_USER"]
  password = data.sops_file.watch_secrets.data["UPTIME_KUMA_PASSWORD"]
}

# tofu/uptime-monitors.tf
resource "uptimekuma_monitor" "core" {
  for_each = {
    code    = { url = "https://code.h-and-i.com", name = "Code Server" }
    git     = { url = "https://git.h-and-i.com", name = "Forgejo" }
    beszel  = { url = "https://beszel.h-and-i.com", name = "Beszel" }
    dozzle  = { url = "https://dozzle.h-and-i.com", name = "Dozzle" }
    wud     = { url = "https://wud.h-and-i.com", name = "WUD" }
    auth    = { url = "https://auth.h-and-i.com", name = "Authentik" }
  }
  provider = uptimekuma.kuma
  name     = each.value.name
  type     = "http"
  url      = each.value.url
  interval = 60
}
