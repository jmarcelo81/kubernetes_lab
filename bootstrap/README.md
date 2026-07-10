# ArgoCD + GitOps Foundation

## 1. What it is

This is the GitOps continuous delivery foundation for the cluster, turning `git push` into a cluster state change. CI (Jenkins → Harbor) closes the loop in a later phase. (soon)

Terraform (IaC) and ArgoCD do not overlap; they hand off. Terraform owns what ArgoCD shouldn't — the Vault Kubernetes auth backend now, EKS + Secrets Manager later. ArgoCD owns in-cluster application state, declaratively, from Git. The specific seam Terraform closes here is Vault configuration that would otherwise live outside version control.

The goal is a complete CI/CD pipeline where Git is the source of truth, delivered via ArgoCD.

## 2. How it works

**App-of-apps.** The one object applied by hand is `root-app`. It watches `apps/`, and every Application file there becomes a live app in the cluster. Adding a service is a file + a `git push` — no further `kubectl apply`.

**Merge to `main` is the deployment gate.** ArgoCD reads `origin/main`, not local, so commits sitting on a branch are invisible to the cluster.

**The secret chain** runs Vault (Kubernetes auth backend, Terraform-provisioned) → ESO → native Kubernetes Secret, brokered by the `vault-backend` ClusterSecretStore. Apps consume ordinary `Secret` objects; ESO materializes them from Vault on a reconcile loop.

**Sync waves** enforce ordering. Wave `-2` lands the ESO operator + CRDs; wave `-1` lands the ClusterSecretStore that depends on them. Without waves you get `no matches for kind ClusterSecretStore` — the CRD hasn't installed yet.

**Repo layout:** `bootstrap/` `apps/` `manifests/` `terraform/vault/`.

## 3. Deployment mode and design

- **ArgoCD via Helm**, chart and app version pinned.
- **LAN-only ingress**, Traefik terminating TLS at the edge. ArgoCD runs `server.insecure: true` internally so Traefik owns the cert, not ArgoCD — one cert, one place.
- **ESO via Helm as an ArgoCD Application** (wave `-2`), so the operator itself is under GitOps.
- **ClusterSecretStore as a plain manifest** (wave `-1`), path-sourced from this repo.
- **Vault Kubernetes auth via Terraform** — role bound to the `external-secrets` ServiceAccount in the `external-secrets` namespace.
- **Vault policy scoped to `secret/data/*` and `secret/metadata/*`** — the KV v2 API's data and metadata paths. No wildcard on the mount root, no other secrets engines reachable.
- **Smoketest before trust.** Tested with a throwaway ESO probe which validated the full Vault → ESO → native Secret chain end-to-end before ArgoCD was handed the store. The chain was proven before it was automated on top of.

## 4. Gotchas

**A) Vault mount path: `secret`, not `kv`.** The ClusterSecretStore must reference the actual KV mount, which is `secret/`. If it reads `kv`, Kubernetes auth *succeeds* and every read fails permission-denied — silent, hardest failure mode to spot. Lesson: `vault secrets list` before writing any store or Terraform config.

**B) A sealed Vault stops secret *syncs*, not running pods.** When Vault seals (after a kube002 reboot, for example), ExternalSecrets stop reconciling and any new sync fails. Pods already holding materialized `Secret` objects keep running; the damage is to rotation and to anything created after the seal. Unseal with 3 of 5 keys and the chain heals on the next reconcile.

**C) Guard secret material by location, not filename.** A `.gitignore` pattern like `*secret*.yaml` silently swallows ESO reference manifests — ExternalSecret and ClusterSecretStore objects that carry only Vault *references*, no values. Guard actual secret material by location (`secrets/`) and specific extensions (`*.key`, `*.pem`, `*.tfvars`), never by the word "secret" in a filename.

**D) Committed ≠ deployed.** ArgoCD reads `origin/main` on its own ~3-minute reconcile poll. A local commit that hasn't been pushed is invisible; a pushed commit takes up to the poll interval to appear. Force a re-read when you don't want to wait:

```
kubectl -n argocd annotate application <name> argocd.argoproj.io/refresh=hard --overwrite
```

## 5. What's next

A) Grow the cluster and add a NAS.
B) Harbor private registry.
C) Close the Jenkins → Harbor → ArgoCD CI/CD loop, and add a second ESO SecretStore against AWS Secrets Manager as the cloud-agnostic proof — with an EKS cluster registered in this ArgoCD for hybrid multi-cluster GitOps.

These are later phases to expand learning, demonstrate cloud-agnostic work, and simulate a real production workflow.
