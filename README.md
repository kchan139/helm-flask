# Flask + PostgreSQL on Kubernetes

Flask web application with PostgreSQL backend deployed on Kubernetes (k3s) using Helm.

## Architecture

- **Backend**: Flask voting/polling app, 
- **Database**: PostgreSQL 17 StatefulSet
- **Ingress**: Routes traffic to Flask service (Supports HTTPS)
- **Autoscaling**: HPA scales on CPU usage
- **Security**: 
  - NetworkPolicy restricts database access
  - **Sealed Secrets** for encrypted credential management
- **Monitoring**: *Prometheus-community kube-prometheus-stack* is deployed

## Prerequisites

- K3s cluster
- Helm 3
- kubectl/kubeseal 
- docker or podman

## Quick Start
The deployment scripts automatically target the `dev` environment by default.

```bash
# 1. Build and import images
./scripts/build.sh

# 2. Install Infrastructure (Controllers & Monitoring)
./scripts/install-sealed-secrets.sh
./scripts/install-cert-manager.sh
./scripts/install-promstack.sh

# 3. Generate Encrypted Secrets
# Follow the prompts to set DB credentials for the target environment
./scripts/create-sealed-secrets.sh dev

# 4. Deploy Application
./scripts/apply.sh dev

# 5. Access via port-forward
./scripts/port-forward.sh
```

**Monitoring Dashboards:**

  * **Grafana:** http://localhost:3000
  * **Prometheus:** http://localhost:9090

## Configuration

The project supports three deployment environments: **`dev`**, **`staging`**, and **`prod`**.

| Environment | Helm Values File | Default Namespace |
| :--- | :--- | :--- |
| **dev** | `helm/values-dev.yaml` | `dev` |
| **staging** | `helm/values-staging.yaml` | `staging` |
| **prod** | `helm/values-prod.yaml` | `prod` |

### Secrets Management

This project uses **Bitnami Sealed Secrets**. Secrets are NOT stored in plain text.
To generate a new secret (e.g., database credentials), run:

```bash
./scripts/create-sealed-secrets.sh [env]
```

This will generate an encrypted `sealedsecret-[env].yaml` file in the database chart templates.

### SSL Configuration (.env)

To configure the email used for Let's Encrypt certificates (staging/prod), create a `.env` file:

```bash
cp .env.example .env
# Edit SSL_EMAIL in .env
```

## Utility Scripts

The `scripts/` directory contains helpers for managing the application

| Script | Description |
| :--- | :--- |
| `./build.sh [tag]` | Builds Docker images and imports them into k3s (default tag: `latest`) |
| `./apply.sh [env]` | Deploys the application to the specified environment |
| `./cleanup.sh [env]` | Uninstalls the Helm release and monitors |
| `./create-sealed-secrets.sh` | Interactive script to encrypt DB credentials into a SealedSecret |
| `./install-cert-manager.sh` | Installs Jetstack Cert-Manager for SSL certificates |
| `./install-sealed-secrets.sh` | Installs the Sealed Secrets controller |
| `./install-promstack.sh` | Installs the Prometheus/Grafana monitoring stack |
| `./port-forward.sh` | Starts port-forwarding for Traefik, Grafana, and Prometheus |
| `./stress-flask.sh` | Generates concurrent load against the `/stress` endpoint |
| `./watch-scaling.sh` | Watches pod and HPA status across all environments |

## Structure
```
helm-flask
├── backend
│   ├── templates
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── database
│   ├── Dockerfile
│   └── init.sql
├── helm
│   ├── charts
│   ├── templates
│   ├── Chart.yaml
│   └── values-*.yaml
├── scripts
└── .env
```
