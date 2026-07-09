resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.auth_backend_path
}

# Deliberately minimal. We do NOT set token_reviewer_jwt or kubernetes_ca_cert:
# with disable_local_ca_jwt defaulting to false, Vault uses its OWN pod's
# ServiceAccount token + the in-cluster CA to call the TokenReview API at auth
# time. Cleaner state, more portable — It REQUIRES Vault's ServiceAccount to
# hold system:auth-delegator. The Vault Helm chart creates that binding by
# default; confirm with:  kubectl get clusterrolebinding | grep vault
resource "vault_kubernetes_auth_backend_config" "this" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = var.kubernetes_host
}
