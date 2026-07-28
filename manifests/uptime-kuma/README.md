# Uptime Kuma

## 1. What it is

Uptime Kuma is a self-hosted uptime monitoring tool. It watches my services and alerts me when something goes down.

It replaces any reliance on external monitoring SaaS — the monitoring stack is self-contained alongside the services it watches.

## 2. Facts

- **Image:** `louislam/uptime-kuma:2.3.0`
- **Deployment:** raw manifest (no Helm)
- **Namespace:** `uptime-kuma`
- **URL:** uptime.jmarcelocarvalho.com
- **Storage:** 2Gi local-path PVC (monitor config + history database)
- **Node:** no nodeSelector — schedules on any available worker
- **Ingress:** Traefik + cert-manager (letsencrypt-cloudflare) + CrowdSec bouncer middleware
- **Exposure:** public (status page readable; admin panel requires login)

## 3. Deployment mode and design

Single pod deployment with a persistent volume for monitor configuration and check history.
Uptime Kuma stores everything in its own internal SQLite database — no external database
dependency.

The `Recreate` rollout strategy is used for the same reason as Linkding: the local-path PVC
is `ReadWriteOnce` and can't be shared between pods during a rolling update.

CrowdSec bouncer middleware is applied at the ingress level, so all HTTP traffic passes
through the CrowdSec decision engine before reaching the pod.

## 4. Deployment steps

Create the manifest directory:

```bash
mkdir -p ~/k3s-manifests/uptime-kuma
```

Apply the manifest:

```bash
kubectl apply -f ~/k3s-manifests/uptime-kuma/uptime-kuma.yaml
```

Watch it come up:

```bash
kubectl get pods -n uptime-kuma -w
```

Verify the TLS certificate was issued:

```bash
kubectl get certificate -n uptime-kuma
```

First login creates the admin account through the web UI — no CLI step required.

## 5. Gotchas

**A) Admin setup is web UI only.** Unlike Linkding, there is no pre-flight secret or CLI
step. Navigate to `https://uptime.jmarcelocarvalho.com` on first boot and create the admin
account through the setup wizard before the instance is publicly reachable.

**B) Filename typo on initial deploy.** The file was initially saved as `uptime-kumas.yaml`
(extra `s`), which meant the first `kubectl apply` targeted the wrong path. Renamed with:

```bash
mv k3s-manifests/uptime-kuma/uptime-kumas.yaml k3s-manifests/uptime-kuma/uptime-kuma.yaml
```

Worth double-checking filenames before applying manifests.

## 6. Access model

Publicly exposed via Traefik ingress (HTTPS). The status page is publicly readable. The
admin panel (monitor configuration, alert rules) requires login.

## 7. What's next

- Add monitors for all remaining services as they are deployed
- Configure alert notifications (Discord, email, or Telegram — TBD)
- Explore Prometheus metrics export once that stack is deployed
- Evaluate pinning to a specific node via `nodeSelector` once workload distribution
  across `kube001`/`kube002`/`kube003` is better understood
- Migrate services to Helm as a progression when I need to upgrade it\
