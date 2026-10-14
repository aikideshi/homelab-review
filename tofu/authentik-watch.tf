# PHASE 04 - Watch Authentik apps (Proxy Forward Auth via Caddy import)
# Requires _authentik_shared.tf to be present

locals {
  watch_apps = {
    uptime = {
      slug = "uptime"
      name = "Uptime Kuma"
      group = "Uptime"
      external_host = "https://uptime.h-and-i.com"
    }
    beszel = {
      slug = "beszel"
      name = "Beszel"
      group = "Beszel"
      external_host = "https://beszel.h-and-i.com"
    }
    dozzle = {
      slug = "dozzle"
      name = "Dozzle"
      group = "Dozzle"
      external_host = "https://dozzle.h-and-i.com"
    }
    wud = {
      slug = "wud"
      name = "WUD"
      group = "WUD"
      external_host = "https://wud.h-and-i.com"
    }
  }
}

resource "authentik_provider_proxy" "watch" {
  for_each = local.watch_apps

  name                = each.value.name
  authorization_flow  = data.authentik_flow.default_provider_authorization.id
  invalidation_flow   = data.authentik_flow.default_invalidation_flow.id
  external_host       = each.value.external_host
  mode                = "forward_single"
  access_token_validity = "hours=4"
}

resource "authentik_application" "watch" {
  for_each = local.watch_apps

  name              = each.value.name
  slug              = each.value.slug
  group             = each.value.group
  protocol_provider = authentik_provider_proxy.watch[each.key].id
  meta_description  = "Phase 04 Watch - ${each.value.name}"
  meta_publisher    = "h-and-i homelab"
}

resource "authentik_policy_binding" "watch_admins" {
  for_each = local.watch_apps
  target   = authentik_application.watch[each.key].uuid
  group    = data.authentik_group.admins.id
  order    = 0
}

resource "authentik_outpost_provider_attachment" "watch" {
  for_each = local.watch_apps
  outpost = data.authentik_outpost.embedded.id
  protocol_provider = authentik_provider_proxy.watch[each.key].id
}

output "watch_authentik_hosts" {
  value = { for k, v in local.watch_apps : k => v.external_host }
}
