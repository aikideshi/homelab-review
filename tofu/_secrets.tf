# _secrets.tf - fix watch_secrets only if encrypted
# Your tofu secrets is at tofu/secrets.sops.env (encrypted)
# Ansible secrets at ../secrets/*.sops.env - some may not be sops encrypted yet

data "sops_file" "homelab_secrets" {
  source_file = "secrets.sops.env"
}

data "sops_file" "core_secrets" {
  source_file = "../secrets/core.sops.env"
}

# Only read watch_secrets if it is actually sops encrypted
# If you get "sops metadata not found", encrypt it first:
# sops --encrypt --in-place ../secrets/watch.sops.env
# Or comment this block out until you encrypt it - watch stack does NOT need it in tofu
data "sops_file" "watch_secrets" {
  source_file = "../secrets/watch.sops.env"
}
