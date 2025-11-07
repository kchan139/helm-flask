# Scripts

Helper scripts for building, deploying, and managing the application.

## Build & Deploy

```bash
./build.sh [tag]              # build images with and import to k3s (default: latest)
./apply.sh [env]              # deploy to [env] (default: dev)
./cleanup.sh [env]            # remove deployment from [env] (default: dev)
```

## Monitoring

```bash
./watch-pods.sh [env]         # watch pods in [env] (default: dev)
./port-forward.sh             # forward traefik to localhost:8000
./stop-port-forward.sh
```

## Testing

```bash
./stress-flask.sh             # generate cpu load for hpa testing
```
