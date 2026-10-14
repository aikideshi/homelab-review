# Core Authentik - brand, recovery, Google source, enrollment
# This was previously in authentik.tf - keep it!

resource "authentik_flow" "source_enrollment" {
  name        = "Source Enrollment"
  slug        = "default-source-enrollment-flow"
  title       = "Welcome!"
  designation = "enrollment"
}

resource "authentik_source_oauth" "google" {
  name               = "Google"
  slug               = "google"
  provider_type      = "google"
  consumer_key       = data.sops_file.core_secrets.data["GOOGLE_OAUTH_CLIENT_ID"]
  consumer_secret    = data.sops_file.core_secrets.data["GOOGLE_OAUTH_CLIENT_SECRET"]
  user_path_template = "goauthentik.io/sources/%(slug)s"
  authentication_flow = data.authentik_flow.default_authentication.id
  enrollment_flow     = authentik_flow.source_enrollment.uuid
  access_token_url  = "https://oauth2.googleapis.com/token"
  authorization_url = "https://accounts.google.com/o/oauth2/v2/auth"
  oidc_jwks_url     = "https://www.googleapis.com/oauth2/v3/certs"
  profile_url       = "https://openidconnect.googleapis.com/v1/userinfo"
}

resource "authentik_flow" "recovery" {
  name           = "Recovery"
  slug           = "recovery"
  title          = "Recovery Flow"
  designation    = "recovery"
  authentication = "require_unauthenticated"
}
resource "authentik_stage_identification" "recovery" {
  name          = "Recovery — Identify"
  user_fields   = ["email"]
  recovery_flow = authentik_flow.recovery.uuid
}
resource "authentik_stage_email" "recovery" {
  name     = "Recovery — Email Verification"
  subject  = "Account Recovery — h-and-i.com"
  template = "email/password_reset.html"
}
resource "authentik_flow_stage_binding" "recovery_identify" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_identification.recovery.id
  order  = 0
}
resource "authentik_flow_stage_binding" "recovery_email" {
  target = authentik_flow.recovery.uuid
  stage  = authentik_stage_email.recovery.id
  order  = 1
}
resource "authentik_brand" "default" {
  domain           = "."
  default          = false
  branding_title   = "h-and-i"
  branding_favicon = "/static/dist/assets/icons/icon.png"
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"
  flow_recovery    = authentik_flow.recovery.uuid
}
