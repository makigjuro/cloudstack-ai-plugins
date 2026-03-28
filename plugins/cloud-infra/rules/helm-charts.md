---
paths:
  - "**/charts/**/*.yaml"
  - "**/charts/**/*.yml"
  - "**/charts/**/*.tpl"
---

# Helm Chart Rules

## Namespace
- Never hardcode a namespace in templates
- Always use `{{ .Release.Namespace }}` so the namespace is controlled at install time

## Standard Labels
- `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `app.kubernetes.io/version`
- `app.kubernetes.io/managed-by: Helm`

## Chart Structure
```
charts/
├── Chart.yaml          # name, version, appVersion
├── values.yaml         # defaults (image, replicas, resources, env)
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── configmap.yaml
    ├── hpa.yaml
    └── _helpers.tpl
```

## Conventions
- Service names in charts should match the deployed service names (e.g., `api-gateway`, `user-service`, `order-processor`)
- Health check paths: `/health/live` (liveness), `/health/ready` (readiness) — adjust to match your application's actual health endpoints
- Resource limits always defined in values.yaml
- Environment variables from ConfigMaps and Secrets, not hardcoded
- Use `{{ include "chart.fullname" . }}` from _helpers.tpl for resource naming
