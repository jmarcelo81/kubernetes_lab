output "auth_backend_path" {
  description = "Mount path of the Kubernetes auth backend (use as mountPath in the ClusterSecretStore)."
  value       = vault_auth_backend.kubernetes.path
}

output "role_name" {
  description = "Vault role name (use as role in the ClusterSecretStore auth block)."
  value       = vault_kubernetes_auth_backend_role.external_secrets.role_name
}

output "policy_name" {
  value = vault_policy.external_secrets.name
}
