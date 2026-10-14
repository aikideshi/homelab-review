# ==============================================================================
# FORGEJO — Native OAuth2/OIDC
# ==============================================================================
resource "random_password" "forgejo_oauth_secret" {
  length  = 32
  special = false
}

resource "authentik_provider_oauth2" "forgejo" {
  name               = "forgejo"
  client_id          = "forgejo"
  client_secret      = random_password.forgejo_oauth_secret.result
  authorization_flow = data.authentik_flow.default_provider_authorization.id
  grant_types        = ["authorization_code", "refresh_token"]
  client_type        = "confidential"
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id

  allowed_redirect_uris = [
    {
      matching_mode       = "strict"
      redirect_uri_type   = "authorization"
      url                 = "https://git.h-and-i.com/user/oauth2/authentik/callback"
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id
  ]
}

resource "authentik_application" "forgejo" {
  name              = "Forgejo"
  slug              = "forgejo"
  protocol_provider = authentik_provider_oauth2.forgejo.id
  group             = "DevOps"
}

# ==============================================================================
# TERMIX — Native OAuth2/OIDC
# ==============================================================================
resource "random_password" "termix_oidc_secret" {
  length  = 32
  special = false
}

resource "authentik_provider_oauth2" "termix" {
  name               = "termix"
  client_id          = "termix"
  client_secret      = random_password.termix_oidc_secret.result
  authorization_flow = data.authentik_flow.default_provider_authorization.id
  grant_types        = ["authorization_code", "refresh_token"]
  client_type        = "confidential"
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id

  allowed_redirect_uris = [
    {
      matching_mode       = "strict"
      redirect_uri_type   = "authorization"
      url                 = "https://termix.h-and-i.com/plugin-api/sso/callback"
    }
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id
  ]
}

resource "authentik_application" "termix" {
  name              = "Termix"
  slug              = "termix"
  protocol_provider = authentik_provider_oauth2.termix.id
  group             = "DevOps"
}

# ==============================================================================
# CODE-SERVER — Forward Auth (Proxy Provider)
# ==============================================================================
resource "authentik_provider_proxy" "code_server_proxy" {
  name               = "code-server-proxy"
  external_host      = "https://code.h-and-i.com"
  internal_host      = "http://${var.devops_ip}:${var.code_server_port}"
  mode               = "forward_single"
  authorization_flow = data.authentik_flow.default_authentication.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
}

resource "authentik_application" "code_server" {
  name              = "Code-Server"
  slug              = "code-server"
  protocol_provider = authentik_provider_proxy.code_server_proxy.id
  group             = "DevOps"
}

resource "authentik_policy_binding" "code_server_proxy" {
  target = authentik_application.code_server.uuid
  group  = data.authentik_group.admins.id
  order  = 0
}

resource "authentik_outpost_provider_attachment" "code_server" {
  outpost           = data.authentik_outpost.embedded.id
  protocol_provider = authentik_provider_proxy.code_server_proxy.id
}

# ==============================================================================
# OUTPUTS
# ==============================================================================
output "forgejo_oauth_client_secret" {
  value     = random_password.forgejo_oauth_secret.result
  sensitive = true
}

output "termix_oidc_client_secret" {
  value     = random_password.termix_oidc_secret.result
  sensitive = true
}
