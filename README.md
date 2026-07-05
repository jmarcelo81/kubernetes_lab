# KUBERNETES

## 1. What it is
I am using this repository to create apps/services on my homelab using k3s pods. The long term goal is to become a good Cloud Engineer / Site Reliability Engineer and progress with my career in technology

## 2. Facts

The services to be deployed are for learning CI/CD pipelines, how the tools are used by engineers and how they interact with each other, which function they perform (Which problem they solve) and additionally I am deploying some apps on my lab for self hosting.

- [Linkding](./linkding/README.md) — bookmark manager
- [Uptime Kuma](./uptime-kuma/README.md) — uptime monitoring
- [Gitea](./gitea/README.md) — self-hosted git
- [HashiCorp Vault](./vault/README.md) — secrets management
- [Password Manager](./vaultwarden/README.md) — self-hosted password vault
- [Prometheus & Grafana](./monitoring/README.md) - cluster health monitoring
- [Wazuh](./wazuh/README.md) - To be created


### To be deployed

- **Ansible**
- **Netbox**
- **Immich**
- **Jellyfin**
- **NextCloud**

## 3. Deployment

I am deploying these services as pods on my K3s cluster that I am running on my homelab. I have 4 used computers that I am using as:
- **Control Plane:** kubecp
- **Worker Nodes:** kube001, kube002, and kube003

## 4. Gotchas
None yet.

## 5. What's Next

Once every service is running as intended, the plan is to integrate Argo CD and GitHub actions and ensure that pods are automatically replaced once they become unhealthy, that my website updates have an automated end to end pipeline, and that the changes are recorded both in GitHub and my Gitea instance.
