# Prometheus & Grafana (kube-prometheus-stack)

## 1. What it is

Prometheus & Grafana work in tandem as the core observability tool in IT analysis and monitoring.

Prometheus is an open source monitoring system that scrapes real time metrics about CPU, RAM memory, disk utilization, request rates, kubernetes pods health and availability and so much more. 

Grafana is a dashboard tool that allow users to create dashboards to visualize their data and their systems health. Additionally it's possible to use ConfigMap to store Grafana dashboard configurations in Kubernetes ConfigMaps

## 2. Facts

- **Image:** prometheus-community/kube-prometheus-stack version 87.4.0
- **Deployment:** helm
- **Namespace:** `monitoring`
- **URL:** grafana.jmarcelocarvalho.com (internal)
- **Retention:** 7 days, 20GB cap (home lab, limited resources)
- **Storage:** (local-path PVCs): Prometheus 25Gi · Grafana 5Gi · Alertmanager 5Gi
- **Node:** kubecp - This node has the most RAM (32GB), and local-path pins PVC data to the node, so the stateful components are deliberately co-located there
- **Ingress:** Traefik + cert-manager (letsencrypt-cloudflare, DNS-01)
- **Exposure:** internal only (admin panel requires login, available only in the internal network)

## 3. Deployment mode and design

The stateful components (Prometheus, Alertmanager, Grafana) are pinned to kubecp and keep 7 days of data on persistent volumes. Enough history for a home lab without letting Prometheus grow
unbounded on limited resources.

Prometheus and Alertmanager run as StatefulSets, where each pod gets its own PVC. Grafana runs as a Deployment on a ReadWriteOnce local-path PVC, so it uses the Recreate
strategy. It's the same reasoning as Linkding: a RWO volume can't be shared between the old and new pod during a rolling update, so the old pod has to fully release it before the new one starts.


## 4. Deployment steps

I. Create the Grafana admin secret before installing it as the chart references it via existingSecret, so it must already exist (keeps the password out of Git):

```bash
kubectl create namespace monitoring
kubectl -n monitoring create secret generic grafana-admin \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='<strong-password>'
```

II. Add the Helm repo:
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

III. Install the stack (pinned version, custom values):

```bash   
helm install kube-prom prometheus-community/kube-prometheus-stack \
  --version 87.4.0 -n monitoring -f values.yaml
```

IV. Wait for the operator and CRDs to come up — the ServiceMonitor CRD must exist before applying any ServiceMonitors; then apply the Ingress and the monitors:

```bash
kubectl apply -f grafana-ingress.yaml
kubectl apply -f service_monitor_vault.yaml
kubectl apply -f service_monitor_gitea.yaml
```

V. Add an internal DNS override for grafana.jmarcelocarvalho.com → kubecp so it resolves on the LAN.

VI. Verify in Prometheus → Status → Targets: Vault (single target), Gitea, four node-exporters, kubelet/cAdvisor, and kube-state-metrics all up, with no K3s control-plane targets present.

## 5. Gotchas

A) ServiceMonitor selectors match Service metadata labels, not pod selectors. A ServiceMonitor's selector.matchLabels matches the labels on the Service's metadata, not the pod selector inside the Service. The Gitea Service needed its own app: gitea metadata label to be discoverable. The spec.selector: app: gitea (which selects pods) is invisible to Prometheus. Missing metadata labels = zero targets, with no error anywhere.

B) A 401 with a verified-matching token is a scrape-config problem, not a secret problem. Gitea's /metrics returned 401 even though the bearer token matched in all three places (both secrets and live in app.ini). 
The cause was a missing authorization block on the ServiceMonitor — Prometheus was scraping with no auth header at all. Also note the nesting: name/key go under authorization.credentials, not directly under authorization.

C) Vault exposes multiple services that share labels — watch for duplicate targets. Five Vault services share app.kubernetes.io/name: vault. Selecting on that alone matches four of them, all resolving to the same pod = duplicate targets. The vault-active: "true" label is unique to the vault-active service, and it's also the correct target since /v1/sys/metrics is only served by the active node.

D) cert-manager finalize-404 and the backoff reset. A transient ACME finalize failure (404 Certificate not found) leaves the Order stuck in errored, and deleting the Order / CertificateRequest does not reset the exponential backoff timer. 
Deleting the Certificate object itself lets the ingress-shim recreate it with a zeroed attempt counter, which forces a clean
re-issue. (Node clock skew can cause the same finalize error, so timedatectl is worth a check if it recurs.)

E) Check a community dashboard's datasource type before importing. Many older Grafana.com dashboards are built for InfluxDB or Graphite and are silently useless on a Prometheus stack.
The import prompt asking for DS_INFLUXDB is the tell. Confirm the datasource type on the import screen is Prometheus before importing.

F) Distroless images have no curl or wget (or neither). Endpoint verification differs per image: Vault's distroless image has wget but not curl; the Prometheus image has neither, so use a port-forward and query the API from the workstation instead of exec-ing into the pod.

## 6. Access model

Privately exposed with Traefik ingress (HTTPS), and a login is required

## 7. What's next

- Store the Vault and Gitea dashboards in Kubernetes ConfigMaps (dashboards-as-code) so they're version-controlled and redeployed automatically by the Grafana sidecar, instead of click-imported.
- Replace the placeholder Vault dashboard with a lean, hand-built one scoped to the single-node setup.