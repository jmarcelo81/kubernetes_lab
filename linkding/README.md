# Linkding

## 1. What it is

Linkding is a self-hosted bookmark manager. The goal is a clean, searchable, tag-based
archive of useful links — documentation, tools, references — that lives on my own
infrastructure rather than a third-party service.

## 2. Facts

- **Image:** `sissbruecker/linkding:1.45.0-alpine`
- **Deployment:** raw manifest (no Helm)
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

## 4. Deployment steps

Create the namespace:

```bash
kubectl create namespace linkding
```

Create the superuser secret (do this before applying the manifest — the pod will fail to
start without it):

```bash
kubectl create secret generic linkding-superuser \
  --namespace linkding \
  --from-literal=password='<your-password>'
```

Apply the manifest:

```bash
kubectl apply -f ~/k3s-manifests/linkding/linkding.yaml
```

Watch it come up:

```bash
kubectl get pods -n linkding -w
```

Verify the TLS certificate was issued:

```bash
kubectl get certificate -n linkding
```

Verify the site is live:

```bash
curl -I https://links.jmarcelocarvalho.com
```

## 5. Gotchas

**A) Secret must exist before applying the manifest.** The deployment references
`linkding-superuser` as an `envFrom` secret. If the secret doesn't exist when the pod
starts, it will crash. Always run the `kubectl create secret` step first.

**B) No CrowdSec middleware on this ingress.** Unlike Gitea and Uptime Kuma, the Linkding
ingress only sets `router.entrypoints: websecure` — the CrowdSec bouncer annotation is
absent. This was the state at initial deployment and should be reviewed: adding
`traefik.ingress.kubernetes.io/router.middlewares: kube-system-crowdsec-bouncer@kubernetescrd`
to the ingress annotations would bring it in line with the other services.

**C) Replicas must stay at 1.** SQLite + `ReadWriteOnce` PVC means scaling beyond 1 replica
will cause the second pod to fail to mount the volume. If HA is ever needed, migrating to
PostgreSQL would be the path.

## 6. Access model

Publicly exposed via Traefik ingress (HTTPS). Login is required to access bookmarks — there
is no anonymous read mode. The superuser account is `marcelo`, password stored in the
`linkding-superuser` Kubernetes Secret.

## 7. What's next

- Add the CrowdSec bouncer middleware to the ingress annotation (align with other services)
- Set up automated PVC backup for the SQLite database
- Explore the Linkding browser extension for faster bookmarking
- Evaluate enabling Wayback Machine snapshot archiving (would require bumping PVC size)
- Migrate services to Helm as a progression when I need to upgrade it. It will be done organically
