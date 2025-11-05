# Flask + PostgreSQL on Kubernetes

Flask web application with PostgreSQL backend deployed on Kubernetes (k3s) using Helm.

## Architecture

- **Backend**: Flask app, tracks visit counts
- **Database**: PostgreSQL 17 StatefulSet
- **Ingress**: Routes traffic to Flask service
- **Autoscaling**: HPA scales on CPU usage
- **Security**: NetworkPolicy restricts database access

## Prerequisites

- K3s cluster
- Helm 3
- kubectl configured
- docker or podman

## Quick Start

```bash
# Build and import images
./scripts/build.sh

# Deploy application
./scripts/apply.sh

# Access via port-forward
./scripts/port-forward.sh
```

> App available at [http://localhost:8000](http://localhost:8000)

## Configuration

Secrets in `helm/charts/database/templates/.secret.yml`:
- DB_NAME: `appdb`
- DB_USER: `postgres`
- DB_PASSWORD: `postgres`

Copy `.secret.example.yml` and encode values with `echo -n '<value>' | base64`

> Note: Secrets in Kubernetes are not encrypted, just encoded

## Endpoints

- `GET /` - Main endpoint, increments visit counter
- `GET /health` - Readiness probe (checks DB connection)
- `GET /alive` - Liveness probe
- `GET /stress?duration=30` - CPU stress test for HPA

## Components

**Backend** (`helm/charts/backend/`)
- Deployment: 1 replica (HPA managed), resource limits, probes
- ConfigMap: Database host configuration
- Service: ClusterIP on port 5000
- HPA: Scales based on CPU

**Database** (`helm/charts/database/`)
- StatefulSet: Single replica with 1Gi persistent volume
- NetworkPolicy: Blocks all traffic except from Flask pods
- Service: Headless service on port 5432

## Utility Scripts

- `cleanup.sh` - Delete helm release
- `stress-flask.sh` - Generate load for HPA testing
- `watch-pods.sh` - Monitor pod scaling
- `stop-port-forward.sh` - Stop port-forwarding process

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
│   └── values.yaml
├── scripts
└── .gitignore
```
