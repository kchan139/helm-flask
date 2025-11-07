# Flask + PostgreSQL on Kubernetes

Flask web application with PostgreSQL backend deployed on Kubernetes (k3s) using Helm.

## Architecture

- **Backend**: Flask app, tracks visit counts
- **Database**: PostgreSQL 17 StatefulSet
- **Ingress**: Routes traffic to Flask service
- **Autoscaling**: HPA scales on CPU usage
- **Security**: NetworkPolicy restricts database access
- **Monitoring**: *Prometheus-community kube-prometheus-stack* is deployed

## Prerequisites

- K3s cluster
- Helm 3
- kubectl configured
- docker or podman

## Quick Start
The deployment scripts automatically target the `dev` environment by default, using the `dev` namespace and configuration

```bash
# Build and import images
./scripts/build.sh

# Deploy application
./scripts/apply.sh
./scripts/apply.sh dev

# Access via port-forward
./scripts/port-forward.sh
```

> App available at [http://localhost:8000](http://localhost:8000)

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

Secrets in `helm/charts/database/templates/.secret.yml`:
- DB\_NAME: `appdb` (encoded as `YXBwZGI=`)
- DB\_USER: `postgres` (encoded as `cG9zdGdyZXM=`)
- DB\_PASSWORD: `postgres` (encoded as `cG9zdGdyZXM=`)

Copy `.secret.example.yml` and fill in the values

> Note: Secrets in Kubernetes are not **encrypted**, just **encoded**

## Endpoints

The Flask application exposes the following endpoints on port **5000**

| Endpoint | Purpose |
| :--- | :--- |
| `GET /` | Increments the visit counter in database and returns the current count |
| `GET /alive` | Basic liveness check |
| `GET /health` | **Readiness Probe**. Checks for a successful connection to the PostgreSQL database |
| `GET /metrics` | Exposes Prometheus metrics  |
| `GET /stress?duration=30` | CPU stress test endpoint to trigger HPA scaling. Duration in seconds (default is 30) |


## Utility Scripts

The `scripts/` directory contains helpers for managing the application

| Script | Description |
| :--- | :--- |
| `./build.sh [tag]` | Builds the Flask and Postgres Docker images and imports them into k3s (default tag: `latest`) |
| `./apply.sh [env]` | Deploys the application and monitoring stack to the specified environment (`dev`, `staging`, `prod`) |
| `./cleanup.sh [env]` | Uninstalls the Helm release and scales down monitoring components |
| `./port-forward.sh` | Starts port-forwarding for Traefik (8000), Grafana (3000), and Prometheus (9090) |
| `./stop-port-forward.sh` | Stops the background port-forward process |
| `./stress-flask.sh` | Generates concurrent load against the `/stress` endpoint to test HPA scaling |
| `./watch-pods.sh [env]` | Watches pod status in the deployed namespace |
| `./get-grafana-creds.sh` | Retrieves Grafana admin username and password |

## Structure
```
helm-flask
├── backend
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── database
│   ├── Dockerfile
│   └── init.sql
├── helm
│   ├── charts
│   │   ├── backend
│   │   └── database
│   ├── .helmignore
│   ├── Chart.yaml
│   ├── values-dev.yaml
│   ├── values-staging.yaml
│   └── values-prod.yaml
├── scripts
└── .gitignore
```
