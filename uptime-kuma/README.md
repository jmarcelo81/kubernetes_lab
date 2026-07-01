# Uptime Kuma

## 1. What it is

Uptime Kuma is a self-hosted uptime monitoring tool. It watches my services and alerts me when something goes down.

It replaces any reliance on external monitoring SaaS for lab services — the monitoring stack is self-contained alongside the services it watches.

## 2. Facts

- **Helm Chart / Manifest:** <fill in>
- **Uptime Kuma:** <fill in version>
- **Namespace:** `uptime-kuma`
- **URL:** status.jmarcelocarvalho.com
- **Storage:** <fill in> local-path PVC
- **Node:** pinned to `<fill in>`
- **Exposure:** public (status page is publicly readable)

## 3. Deployment mode and design

Single pod deployment with a persistent volume for monitor config and history. Uptime Kuma stores everything internally — no external database.

It monitors all other services in the cluster (Gitea, Linkding, Vault UI, the portfolio site) via HTTP/HTTPS checks, with configurable intervals and alert thresholds.

Notification alerts go to <fill in — Discord, email, Telegram?>.

## 4. Deployment steps

Create namespace and manifest directory:

```bash
kubectl create namespace uptime-kuma
mkdir -p ~/k3s-manifests/uptime-kuma
```

Apply manifests:

```bash
kubectl apply -f ~/k3s-manifests/uptime-kuma/
```

Check rollout:

```bash
kubectl get pods -n uptime-kuma -w
```

First login creates the admin account via the web UI — no CLI step needed.

## 5. Gotchas

<fill in as you hit them>

## 6. Access model

The status page is publicly accessible (read-only). The admin panel requires login and is where monitors and alert rules are configured.

## 7. What's next

- Add monitors for all remaining services as they are deployed
- Configure alerting to PagerDuty or similar once the stack matures
- Explore pushing metrics into Prometheus/Grafana when that stack is deployed