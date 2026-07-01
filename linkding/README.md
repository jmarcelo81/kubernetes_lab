# Linkding

## 1. What it is

Linkding is a self-hosted bookmark manager. The goal is a clean, searchable, tag-based archive of useful links — documentation, tools, references — that lives on my own infrastructure rather than a third-party service.

## 2. Facts

- **Helm Chart / Manifest:** <fill in — Helm or raw manifest?>
- **Linkding:** <fill in version>
- **Namespace:** `linkding`
- **URL:** linkding.jmarcelocarvalho.com
- **Storage:** <fill in> local-path PVC (for SQLite database)
- **Node:** Pods can be scheduled to any node
- **Exposure:** public (DNS A record pointing to cluster ingress)

## 3. Deployment mode and design

Linkding is a lightweight Django app backed by SQLite. No external database dependency — the entire state lives in a single PVC, which makes backup and restore straightforward.

Deployed as a single pod. No HA needed; this is a personal productivity tool, not a critical service.

## 4. Deployment steps

Create namespace and manifest directory:

```bash
kubectl create namespace linkding
mkdir -p ~/k3s-manifests/linkding
```

Apply manifests:

```bash
kubectl apply -f ~/k3s-manifests/linkding/
```

Check rollout:

```bash
kubectl get pods -n linkding -w
```

Create the superuser account (one-time):

```bash
kubectl exec -n linkding -it <pod-name> -- python manage.py createsuperuser
```

## 5. Gotchas

<fill in as you hit them>

## 6. Access model

Publicly exposed via ingress. Login required to access any bookmarks — no anonymous read access.

## 7. What's next

- Set up automated PVC backup for the SQLite database
- Explore the Linkding browser extension for faster bookmarking
- Tag taxonomy cleanup as the bookmark count grows