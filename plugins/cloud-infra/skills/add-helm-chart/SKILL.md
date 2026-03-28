---
name: add-helm-chart
description: Scaffold a new Helm chart with standard templates and values. Use when deploying a new microservice or component to Kubernetes and it needs its own chart.
allowed-tools: Bash, Write, Read, Glob
user-invocable: true
---

# Add Helm Chart

Scaffold a new Helm chart following project conventions.

## Arguments

- `{chart-name}` — Name of the chart (required, e.g., `my-service`, `api-gateway`)

## Configuration

Read `cloudstack.json` from the project root at the start of execution. Extract:
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)
- `K8S_NAMESPACE` = `infrastructure.namespace` (default: detect from existing charts or use project name)

If `cloudstack.json` does not exist, auto-detect by scanning the project structure.

## Process

1. Create the chart directory structure under `{CHARTS_PATH}/{chart-name}/`:

```
{CHARTS_PATH}/{chart-name}/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
```

2. Read the helm-charts rule file (if present) for project conventions. Also scan existing charts in `{CHARTS_PATH}/` to follow established patterns.

3. Generate files following these conventions:
   - Namespace: Use `{{ .Release.Namespace }}` in templates (do not hardcode)
   - Standard Kubernetes labels: `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`
   - Health check paths: `/health/live` (liveness), `/health/ready` (readiness)
   - Resource limits and requests with sensible defaults
   - HPA with min 1, max 3 replicas

4. **Chart.yaml** template:
```yaml
apiVersion: v2
name: {chart-name}
description: {description}
type: application
version: 0.1.0
appVersion: "0.1.0"
```

5. **values.yaml** — Include configurable values for:
   - `image.repository`, `image.tag`, `image.pullPolicy`
   - `replicaCount`
   - `resources.requests` and `resources.limits`
   - `service.type`, `service.port`
   - `ingress.enabled`, `ingress.hosts`
   - `env` (environment variables as key-value map)

6. Validate the chart:
```bash
helm lint {CHARTS_PATH}/{chart-name}
helm template test {CHARTS_PATH}/{chart-name} > /dev/null
```

## Output

After scaffolding, report:
```
## Scaffolded: {chart-name} Helm chart

Files created:
- `{CHARTS_PATH}/{chart-name}/Chart.yaml`
- `{CHARTS_PATH}/{chart-name}/values.yaml`
- `{CHARTS_PATH}/{chart-name}/templates/_helpers.tpl`
- `{CHARTS_PATH}/{chart-name}/templates/deployment.yaml`
- `{CHARTS_PATH}/{chart-name}/templates/service.yaml`
- `{CHARTS_PATH}/{chart-name}/templates/configmap.yaml`
- `{CHARTS_PATH}/{chart-name}/templates/ingress.yaml`
- `{CHARTS_PATH}/{chart-name}/templates/hpa.yaml`

Validation: helm lint {PASS/FAIL}

Next: Customize `values.yaml` for the specific service, then run `/infra-lint helm`.
```

## Error Handling

- **Chart directory already exists:** Warn the user and ask whether to overwrite or extend the existing chart.
- **Helm not installed:** Suggest installing with `brew install helm`.
- **Lint fails after scaffolding:** Review template syntax — common issues are missing `{{- include }}` helpers or incorrect indentation.

## After Scaffolding

Remind to:
- Customize `values.yaml` for the specific service
- Add environment-specific value overrides if needed
- Update any umbrella chart dependencies if applicable
