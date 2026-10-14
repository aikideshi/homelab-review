# Shared Authentik data sources - SINGLE source of truth
data "authentik_group" "admins" {
  name = "authentik Admins"
}

data "authentik_flow" "default_authentication" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_flow" "default_provider_authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_outpost" "embedded" {
  name = "authentik Embedded Outpost"
}

data "authentik_property_mapping_provider_scope" "openid" {
  managed = "goauthentik.io/providers/oauth2/scope-openid"
}
data "authentik_property_mapping_provider_scope" "email" {
  managed = "goauthentik.io/providers/oauth2/scope-email"
}
data "authentik_property_mapping_provider_scope" "profile" {
  managed = "goauthentik.io/providers/oauth2/scope-profile"
}
