# Linkding

## 1. What it is

Linkding is a self-hosted bookmark manager. The goal is a clean, searchable, tag-based
archive of useful links — documentation, tools, references — that lives on my own
infrastructure rather than a third-party service.

## 2. Facts

- **Image:** `sissbruecker/linkding:1.45.0-alpine`
- **Deployment:** Raw manifests managed by ArgoCD (app-of-apps, wave 1)
- **Namespace:** `linkding`
- **URL:** links.jmarcelocarvalho.com
- **Storage:** 2Gi local-path PVC (SQLite database + bookmark archive snapshots)
- **Node:** no nodeSelector — schedules on any available worker
- **Ingress:** Traefik + cert-manager (letsencrypt-cloudflare)
- **Exposure:** public (login required — no anonymous read access)

## 3. Deployment mode and design

Linkding is a lightweight Django app backed by SQLite. No external database dependency —
the entire state lives in a single PVC, which keeps backup and restore straightforward.

Replicas are locked to 1 and the rollout strategy is `Recreate`. This is intentional and
must not be changed: SQLite plus a `ReadWriteOnce` local-path volume cannot be safely shared
across multiple pods.

The superuser password is injected via a Kubernetes Secret (`linkding-superuser`) referenced
in the deployment env. That secret is **not** in the manifest file and **not** committed to
git — it must be created manually before applying the manifest (see section 4).

The superuser password lives in Vault at `secret/linkding` (key: `password`). An ExternalSecret
in the `linkding` namespace watches that path via the `vault-backend` ClusterSecretStore and
renders a native Kubernetes Secret (`linkding-superuser`) which the deployment mounts via `envFrom`.
Nothing sensitive is committed to Git.

## 4. Deployment steps

This service is fully managed by ArgoCD. There are no manual `kubectl apply`
or `kubectl create secret` steps — that pattern is documented here only for
historical reference (see section 5D).

To deploy or update:

1. Edit manifests under `manifests/linkding/` on a feature branch
2. Open a PR against `main`
3. On merge, the root app-of-apps picks up `apps/linkding.yaml` and syncs

To verify the deployment:

```bash
kubectl -n argocd get app linkding
kubectl -n linkding get pod,pvc,ingress,externalsecret
kubectl -n linkding get certificate
curl -I https://links.jmarcelocarvalho.com
```

To rotate the superuser password: update the value in Vault at
`secret/linkding`, then restart the deployment so the pod re-reads the env
(`kubectl -n linkding rollout restart deployment linkding`). ESO refreshes
the K8s Secret on its own interval (default 1h), but the pod won't pick up
env changes without a restart.

## 5. Gotchas

**A) Wave ordering is what makes the ESO-first pattern safe.**
The `linkding-secrets` ArgoCD Application is annotated with sync-wave `-1`
and the workload Application with wave `1`. This ordering ensures the
ExternalSecret exists and has materialized a K8s Secret before the pod
tries to `envFrom` it. If wave ordering is broken, the pod will crashloop
with a missing-secret error until ESO catches up.

**B) No CrowdSec middleware on this ingress.**
Unlike Gitea and Uptime Kuma, the Linkding ingress does not set the
CrowdSec bouncer middleware annotation. Adding
`traefik.ingress.kubernetes.io/router.middlewares: kube-system-crowdsec-bouncer@kubernetescrd`
would align it with the other public services.

**C) Replicas must stay at 1.**
SQLite + `ReadWriteOnce` PVC means scaling beyond 1 replica will cause the
second pod to fail to mount the volume. If HA is ever needed, migrating to
PostgreSQL would be the path.

**D) Migrated from hand-applied to GitOps on 2026-07-28.**
Prior to that, the deployment lived in `linkding/linkding.yaml` at the repo
root, was applied with `kubectl apply -f`, and the superuser secret was
created imperatively via `kubectl create secret generic`. The migration
replaced the imperative secret with an ExternalSecret, so the Vault path
`secret/linkding` must be populated before the app is deployed to a fresh
cluster.

## 6. Access model
Publicly exposed via Traefik ingress (HTTPS). Login is required to access
bookmarks — there is no anonymous read mode. The superuser account is
`marcelo`, password stored in Vault at `secret/linkding`.

## 7. What's next
- Set up automated PVC backup for the SQLite database (candidate for Velero once installed)
- Explore the Linkding browser extension for faster bookmarking
- Evaluate enabling Wayback Machine snapshot archiving (would require bumping PVC size)
