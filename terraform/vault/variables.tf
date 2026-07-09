variable "auth_backend_path" {
  description = "Mount path for the Kubernetes auth backend."
  type        = string
  default     = "kubernetes"
}

variable "kubernetes_host" {
  description = "In-cluster API server address, as seen from the Vault pod."
  type        = string
  default     = "https://kubernetes.default.svc:443"
}

variable "kv_mount_path" {
  description = "Path of the KV v2 secrets engine ESO will read (e.g. kv or secret)."
  type        = string
  default     = "kv"
}

variable "eso_namespace" {
  description = "Namespace the External Secrets Operator runs in."
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account" {
  description = "ServiceAccount name ESO authenticates as (chart default)."
  type        = string
  default     = "external-secrets"
}

variable "role_name" {
  description = "Vault Kubernetes auth role name bound to the ESO ServiceAccount."
  type        = string
  default     = "external-secrets"
}

variable "policy_name" {
  description = "Vault policy granting read on the KV path."
  type        = string
  default     = "external-secrets"
}

variable "token_ttl" {
  description = "TTL (seconds) of tokens Vault issues to ESO."
  type        = number
  default     = 3600
}
