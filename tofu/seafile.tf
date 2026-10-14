resource "random_password" "seafile_oauth_secret" {
  length  = 32
  special = false
}

resource "authentik_provider_oauth2" "seafile" {
  name                = "Seafile"
  client_id           = "seafile"
  client_secret       = random_password.seafile_oauth_secret.result
  authorization_flow  = data.authentik_flow.default_provider_authorization.id
  invalidation_flow   = data.authentik_flow.default_invalidation_flow.id
  authentication_flow = data.authentik_flow.default_authentication.id

  client_type                = "confidential"
  sub_mode                   = "hashed_user_id"
  issuer_mode                = "per_provider"
  include_claims_in_id_token = true

  # FIX for 2026.5+ - MUST set explicitly
  property_mappings = [
    data.authentik_property_mapping_provider_scope.openid.id,
    data.authentik_property_mapping_provider_scope.email.id,
    data.authentik_property_mapping_provider_scope.profile.id,
  ]

  allowed_redirect_uris = [
    {
      url           = "https://seafile.h-and-i.com/oauth/callback/"
      matching_mode = "strict"
    }
  ]
  # NEW in 2026.8.0 provider
  # If terraform says "Unsupported argument" -> use shell workaround below instead
  # Uncomment if provider supports:
  grant_types = ["authorization_code", "refresh_token"]
}
resource "authentik_application" "seafile" {
  name              = "Seafile"
  slug              = "seafile"
  group             = "Storage"
  protocol_provider = authentik_provider_oauth2.seafile.id
  meta_icon         = "https://seafile.com/favicon.ico"
  meta_publisher    = "Seafile"
}

resource "authentik_group" "seafile_users" {
  name = "seafile-users"
}

output "seafile_oauth_client_secret" {
  value     = random_password.seafile_oauth_secret.result
  sensitive = true
}
