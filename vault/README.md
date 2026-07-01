# Vault

## 1. What it is

I'm using HashiCorp Vault for secrets management. The long-term goal is dynamic, short-lived secrets generated on demand rather than static credentials sitting around indefinitely.

Initially, this is the foundation that future pipeline and app secrets will be built on top of.

## 2. Facts

- **Helm Chart:** 0.33.0
- **Vault:** 1.21.2
- **Namespace:** `vault`
- **URL:** vault.jmarcelocarvalho.com
- **Storage:** 5Gi local-path PVC, Raft integrated storage
- **Node:** pinned to `kube002`
- **Exposure:** internal only (no public DNS A record — see section 6)

## 3. Deployment mode and design

I deployed Vault in production mode with Raft integrated storage, rather than dev mode, to mimic a real-world setup and actually learn what matters operationally — this is part of becoming a security-conscious SRE, not just getting a UI to load.

Shamir's Secret Sharing splits the root encryption key into 5 shares, requiring any 3 of them to unseal Vault. This matters because no single key holder (or single leaked key) can unseal Vault alone. It removes any single point of compromise. Unsealing is separate from authentication, though: unsealing just lets Vault start operating on its encrypted storage; you still need a valid login (root token or, now, my userpass account) to actually do anything once it's unsealed.

This runs as a single pod, pinned to `kube002` via `nodeSelector` to keep resource usage predictable across my 4-node lab (`kubecp` is reserved for heavier workloads like Wazuh). It's a single-replica Raft "cluster" due to lab size constraints — true HA would need 3+ nodes for proper quorum, which isn't realistic on my current hardware budget. Migrating to real HA is a future consideration if that changes.

## 4. Deployment steps

Install Helm (one-time):

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version
rm get_helm.sh get-helm-3 2>/dev/null  # cleaning up the install script
```

Add the HashiCorp repo:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

Create namespace and manifest directory:

```bash
kubectl create namespace vault
mkdir -p ~/k3s-manifests/vault
```

Create `~/k3s-manifests/vault/values.yaml` (see repo for full content).

Install:

```bash
helm install vault hashicorp/vault \
  --version 0.33.0 \
  --namespace vault \
  -f ~/k3s-manifests/vault/values.yaml
```

Watch it come up — `vault-0` will sit at `Running` but not `Ready`, which is expected: a freshly deployed Vault pod is uninitialized and sealed until the next two steps.

```bash
kubectl get pods -n vault -w
```

Initialize (generates 5 unseal keys + root token — one-time, save the output securely):

```bash
kubectl exec -n vault -it vault-0 -- vault operator init
```

Unseal (run 3 times with 3 different keys):

```bash
kubectl exec -n vault -it vault-0 -- vault operator unseal
```

## 5. Gotchas

**A) Image tag override.** The chart's default app version points at Vault Enterprise (2.0.2), not OSS. Had to explicitly set `tag: 1.21.2` to get the correct edition.

**B) `kubectl exec` has no auth context.** Being logged into the Vault UI as root in the browser doesn't carry over to a `kubectl exec` session against the pod. Each is a completely separate authentication context. A one-off command like `vault auth enable userpass` run directly via `kubectl exec` failed with a 403, even while authenticated in the UI.

Fix: drop into an interactive shell in the pod and explicitly export the root token there before running any Vault CLI commands:

```bash
kubectl exec -n vault -it vault-0 -- sh
export VAULT_TOKEN="<root-token>"
vault auth enable userpass
```

## 6. Access model

Vault is internal-only by design — it holds real secrets, so it shouldn't be reachable from the public internet at all.

## 7. What's next

- Replace the full-admin policy with scoped, least-privilege policies once I better understand which paths/engines I actually need day-to-day
- Investigate true HA (3+ node Raft quorum) when hardware allows
- Integrate Vault into the update pipeline for my website and for PerfectSpot (my questionnaire app), and move toward dynamic secrets rather than static ones