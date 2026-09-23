# telemetry-stack

[![CI](https://github.com/IliasSoultana/telemetry-stack/actions/workflows/ci.yml/badge.svg)](https://github.com/IliasSoultana/telemetry-stack/actions/workflows/ci.yml)

Helm chart deploying the MQTT / Prometheus / Grafana telemetry stack to
Kubernetes.

Written from scratch as an independent project. It composes three upstream
public images -- eclipse-mosquitto, prom/prometheus and grafana/grafana -- with
Helm templates and configuration written for this repository. It contains no
third-party or employer-owned code, configuration or data.

## Components

| Component | Role |
| --- | --- |
| Mosquitto | MQTT broker receiving device telemetry |
| Prometheus | Metrics storage and scraping, with configurable retention |
| Grafana | Dashboards, with the Prometheus datasource provisioned automatically |

Each Deployment carries liveness and readiness probes, resource requests and
limits, and an optional PersistentVolumeClaim.

## Install on a local cluster

```
k3d cluster create telemetry
helm install telem . --wait
```

Or with kind:

```
kind create cluster --name telemetry
helm install telem . --wait
```

## Verify

```
kubectl get pods,svc,pvc
kubectl port-forward svc/telem-telemetry-stack-grafana 3000:3000
```

Grafana is then at `http://localhost:3000` (`admin` / the password from
`values.yaml`). The Prometheus datasource is already wired up.

Publish a test message to the broker:

```
kubectl port-forward svc/telem-telemetry-stack-mosquitto 1883:1883 &
mosquitto_pub -h localhost -t devices/node01/temp -m 23.4
```

## Configuration

See `values.yaml`. The values most worth overriding:

```
helm install telem . \
  --set grafana.adminPassword=... \
  --set prometheus.retention=30d \
  --set mosquitto.persistence.size=5Gi
```

To scrape a custom exporter, add it to `prometheus.extraTargets`:

```yaml
prometheus:
  extraTargets:
    - name: mqtt-exporter
      targets: ["mqtt-exporter:9234"]
```

## Notes

`mosquitto.allowAnonymous` defaults to `true`, which is appropriate for a local
demo cluster only. For any broker reachable beyond localhost, mount a password
file and set it to `false`.

The Grafana admin password is stored in a Secret rendered from values. For real
deployments, reference an existing Secret instead of passing the password
through Helm.

## Validation

CI lints the chart, renders it with both default and overridden values, and
validates every rendered object against the upstream Kubernetes schemas with
[`kubeconform`](https://github.com/yannh/kubeconform) in strict mode.

Rendering matters more than linting here: `helm lint` passes on templates that
only produce invalid YAML once values are substituted, and strict validation
catches a misspelled field at build time rather than on `kubectl apply`.
