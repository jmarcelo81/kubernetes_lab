# Binds the ESO ServiceAccount (name + namespace) to the read policy.
# Login only succeeds for a token issued to external-secrets/external-secrets.
resource "vault_kubernetes_auth_backend_role" "external_secrets" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.role_name
  bound_service_account_names      = [var.eso_service_account]
  bound_service_account_namespaces = [var.eso_namespace]
  token_policies                   = [vault_policy.external_secrets.name]
  token_ttl                        = var.token_ttl
}
