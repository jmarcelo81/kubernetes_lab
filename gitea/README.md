# Gitea

## 1. What it is

Gitea is a self-hosted Git service — my local alternative to GitHub for storing lab manifests, configs, and project code.

The goal is a private, self-controlled git server that mirrors or complements GitHub, and eventually serves as the source-of-truth for my internal CI/CD pipeline via Argo CD.

## 2. Facts

- **Image:** `gitea/gitea:1.26.4`
- **Deployment:** raw manifest (no Helm)
- **Namespace:** `gitea`
- **URL:** gitea.jmarcelocarvalho.com
- **SSH:** NodePort `30022` (UFW open for `10.10.10.0/24`)
- **Storage:** 10Gi local-path PVC
- **Node:** no nodeSelector — schedules on any available worker
- **Ingress:** Traefik + cert-manager (letsencrypt-cloudflare) + CrowdSec bouncer middleware
- **Exposure:** public (HTTP and SSH)

## 3. Deployment mode and design

Deployed as a single replica using a raw Kubernetes manifest. The `Recreate` rollout strategy
ensures the old pod is fully terminated before a new one starts — required because the 10Gi
local-path PVC is `ReadWriteOnce` and can't be mounted by two pods simultaneously.

SSH is exposed via a dedicated `NodePort` service on port `30022` rather than through the
ingress controller, since Traefik handles HTTP/HTTPS only. A UFW rule on `kubecp` allows
SSH access from within the cluster subnet.

CrowdSec bouncer middleware is applied at the ingress level, meaning all HTTP traffic to Gitea passes through the CrowdSec decision engine before reaching the pod.

## 4. Deployment steps

Open the SSH NodePort in UFW (one-time, run on `kubecp`):

```bash
sudo ufw allow from 10.10.10.0/24 to any port 30022 proto tcp comment 'Gitea SSH NodePort'
```

Create the manifest directory:

```bash
mkdir -p ~/k3s-manifests/gitea
```

Apply the manifest:

```bash
kubectl apply -f ~/k3s-manifests/gitea/gitea.yaml
```

Watch it come up:

```bash
kubectl get pods -n gitea -w
```

Verify the TLS certificate was issued:

```bash
kubectl get certificate -n gitea
```

## 5. Gotchas

**A) SSH via NodePort, not ingress.** Gitea exposes SSH on `30022` through a `NodePort`
service, not through Traefik. The UFW rule must exist on `kubecp` before SSH clones will
work. The `gitea.yaml` sets `SSH_PORT: 30022` and `SSH_DOMAIN: gitea.jmarcelocarvalho.com`
so the clone URLs shown in the UI are correct.

**B) Initial admin setup is done through the web UI.** On first access, Gitea presents an
installation wizard. Complete this before doing anything else — it sets the admin account
and locks the installer.

## 6. Access model

Publicly exposed via Traefik ingress (HTTPS) and NodePort (SSH). Admin credentials are not
stored in the manifest — set during first-run web UI setup.

## 7. What's next

- Connect Gitea as a source repo for Argo CD
- Mirror key GitHub repos into Gitea for full self-hosted redundancy
- Set up Gitea Actions for internal CI runs
- Migrate services to Helm as a progression when I need to upgrade it