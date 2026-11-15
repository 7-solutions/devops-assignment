# Interview notes

Use these notes to explain the choices in the repository. Be precise about whether you ran a component in a real cloud environment or prepared its reproducible configuration.

## A 45-second overview

“I took the supplied Go API and made its runtime observable and safe to stop. I built it as a small non-root container, deployed it with Kustomize using health probes, rolling updates, pod disruption protection, host/zone spreading, and CPU autoscaling. Terraform provisions a regional GKE cluster on a custom VPC with private worker nodes and Workload Identity Federation. GitHub Actions builds a commit-tagged image and raises a separate manifest-update PR; Argo CD deploys the merged Git state. Prometheus, Loki, Tempo, Alloy, and Grafana cover metrics, logs, and traces. I also added an idempotent Ansible playbook for Docker, NGINX, log rotation, and Node Exporter.”

## What I changed and why

### Go service and container

- `/healthz` answers whether the process is alive; `/readyz` gives Kubernetes a separate traffic-readiness check.
- SIGTERM triggers a bounded graceful shutdown so rolling deploys can drain requests instead of cutting them off.
- `/metrics` exports request count and process uptime. OpenTelemetry's HTTP middleware creates server spans; setting `OTEL_EXPORTER_OTLP_ENDPOINT` enables OTLP export.
- The greeting endpoint limits the caller-provided name to 100 bytes so an untrusted query cannot create an arbitrarily large response.
- Structured JSON logs include method, path, status, duration, and trace ID, so Alloy can send them to Loki and operators can correlate logs with Tempo traces.
- The Docker build compiles with CGO disabled and strips debug symbols, then copies only the executable into Docker's static hardened runtime. The application runs as UID 65532.

### Kubernetes reliability and security

- Three replicas are the baseline; the HPA can add replicas up to ten as CPU demand rises.
- Pod anti-affinity separates replicas by node. Topology spread encourages distribution across zones.
- `maxUnavailable: 0`, readiness checks, and a PDB with `minAvailable: 2` keep service capacity during deploys and voluntary node maintenance.
- Resource requests help the scheduler place pods; limits cap how much CPU and memory each pod can consume.
- Restricted namespace policy, non-root UID, read-only filesystem, seccomp, no privilege escalation, and dropped capabilities reduce container privileges.
- The app has no Google API dependency, so it has no GCP IAM role. GKE Workload Identity Federation is enabled for a future least-privilege KSA-to-GSA binding, with no downloaded key JSON.

### Cloud and deployment design

- Terraform separates the VPC, subnet, pod/service IP ranges, Cloud NAT, cluster, and node pool so the setup can be recreated and reviewed.
- Nodes are private. The API endpoint has a public address constrained by an operator CIDR list so a laptop can administer this demonstration cluster. A production cluster with private control-plane access would use VPN, Interconnect, or a controlled bastion.
- The node pool is regional, autoscaled, auto-repaired, auto-upgraded, and uses Shielded VM settings. Its custom node service account gets GKE's required `roles/container.defaultNodeServiceAccount` role.
- CI publishes a commit-SHA image tag, then proposes a separate Kustomize PR. A reviewer approves the desired production version; Argo CD continuously reconciles it. This gives traceability and avoids deployment depending on a CI runner's direct cluster credentials.

### Observability and Ansible

- Prometheus scrapes the app ServiceMonitor and cluster exporters. Alloy reads Kubernetes container logs and receives OTLP traces. Loki stores logs, Tempo stores traces, and Grafana presents the dashboard.
- The one-replica Loki and Tempo configuration uses persistent disks for a compact demonstration. Production would use replicated backends and object storage such as GCS.
- Ansible tasks are declarative so rerunning the playbook converges to the requested state. Docker daemon defaults rotate logs; NGINX serves a Jinja-rendered page; Node Exporter runs under a system user with no shell.

## Likely follow-up questions

**Why use commit SHA image tags instead of `latest`?**

Each manifest points to a build tagged with its source commit. That makes rollbacks and incident investigation easier to trace and avoids relying on the mutable `latest` tag.

**Why have CI open a pull request instead of running `kubectl apply`?**

The PR is the production change record. Argo CD watches Git and deploys only after the manifest change is reviewed and merged; the CI runner never needs cluster-admin credentials.

**How are Google credentials handled?**

The app gets no static GCP key. GKE Workload Identity Federation is enabled. If it needs a Google API later, I would bind a dedicated KSA to a GSA and grant the GSA only that API's required role.

**How do the probes differ?**

Liveness asks Kubernetes to restart a stuck process. Readiness controls whether the Service sends it traffic. Startup probes give slow-starting containers time before liveness checks begin.

**What would you change before a real production launch?**

Use remote, locked Terraform state; private control-plane access through a trusted network; replicated observability backends with object storage; a TLS ingress/Gateway and network policies; image scanning/signing and pinned action digests; and tested backup/restore and alert-response procedures.

## Be honest about completion status

This repository contains the application and deployment code. A public Docker Hub image, live GKE cluster, installed Argo CD/LGTM stack, and configured Ansible host require your account credentials and target environment. Only describe those as deployed after you have run them and captured the resulting evidence. The assignment accepts the IaC code and deployment instructions as explicit outputs for the infrastructure/GitOps portions.
