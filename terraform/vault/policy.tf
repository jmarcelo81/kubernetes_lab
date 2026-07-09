# Read-only, scoped to the KV v2 mount. Note the physical paths:
#   kv/data/*      -> the secret payloads (what ESO actually reads)
#   kv/metadata/*  -> versions/list
# In the ExternalSecret manifests the remoteRef.key is WITHOUT the /data/
# segment (ESO inserts it for KV v2). The policy is written against the real
# physical path WITH /data/.
resource "vault_policy" "external_secrets" {
  name = var.policy_name

  policy = <<-EOT
    path "${var.kv_mount_path}/data/*" {
      capabilities = ["read"]
    }

    path "${var.kv_mount_path}/metadata/*" {
      capabilities = ["read", "list"]
    }
  EOT
}
