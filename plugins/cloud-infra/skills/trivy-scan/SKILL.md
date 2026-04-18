---
name: trivy-scan
description: Scan Terraform and Helm charts for security misconfigurations using trivy. Use for a fast IaC security check — catches issues that `/infra-lint` doesn't (secrets, public-access defaults, missing encryption, weak TLS, over-broad IAM). Invoked automatically by `/infra-lint` and `/complete-infra`.
allowed-tools: Bash, Read
user-invocable: true
---

# Trivy Security Scan

Run Aqua Security's trivy against the infrastructure tree to catch misconfigurations that `terraform validate` and `helm lint` miss — things like publicly exposed storage, missing encryption, weak TLS, over-broad IAM role assignments, and container image vulnerabilities.

## When to Use

- **Directly (`/trivy-scan`)** — manual scan, e.g. while iterating on a module or before a PR.
- **Indirectly** — invoked from `/infra-lint` (fast check) and `/complete-infra` (pre-PR verification gate).

## Arguments

- `--strict` — Fail on any finding, including `LOW`. Default: fail on `CRITICAL`, `HIGH`, `MEDIUM`; `LOW` is advisory.
- `--warn-only` — Never exit non-zero; just report. Useful for CI `continue-on-error` style gating.
- `--severity HIGH,CRITICAL` — Comma-separated list to override the default severity filter.

## Configuration

Read `cloudstack.json` from the project root at start of execution. Extract:
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)

Derive `TF_PARENT` as the parent directory of `TF_PATH` (e.g., `infra/terraform/modules` → `infra/terraform`). If `cloudstack.json` is missing, auto-detect by scanning the project.

## Prerequisites

`trivy` must be installed locally. The skill does NOT auto-install — be explicit about system changes.

```bash
# macOS
brew install trivy

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

If `trivy` is missing, the skill prints the install command and exits non-zero (unless `--warn-only`).

## Suppressing findings — `.trivyignore`

Project-local exemptions go in `deploy/terraform/.trivyignore` (or the parent of `TF_PATH`). One rule ID per line, with a comment explaining **why**:

```
# Deferred until VNet integration (see deploy/terraform/README.md "Known limitations")
AZU-0013
AZU-0022

# Trivy check written for deprecated Single Server; we run Flexible Server
# and set TLS via `require_secure_transport` + `ssl_min_protocol_version`
AZU-0026
```

Every ignore entry MUST carry a justification comment. The comment is what a future reviewer uses to decide whether the suppression is still valid.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/scan-trivy.sh` | Runs trivy against `TF_PARENT` and `CHARTS_PATH`, honouring `.trivyignore` |

The script reads `TF_PARENT` and `CHARTS_PATH` from environment variables. Export them before calling:

```bash
export TF_PARENT="..." CHARTS_PATH="..."
bash {plugin-skills-path}/trivy-scan/scripts/scan-trivy.sh
```

## Process

### Step 1: Pre-flight

Verify `trivy` is available:

```bash
if ! command -v trivy >/dev/null 2>&1; then
  echo "trivy is not installed. Install it and re-run:"
  echo "  brew install trivy   # macOS"
  echo "  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin   # Linux"
  exit 1
fi
```

### Step 2: Run the scan

```bash
export TF_PARENT="{TF_PARENT}" CHARTS_PATH="{CHARTS_PATH}"
bash {plugin-skills-path}/trivy-scan/scripts/scan-trivy.sh
```

### Step 3: Report

Group findings by severity. For each finding, include:
- Rule ID (e.g. `AZU-0013`)
- Severity
- Title
- File:line reference
- Remediation link (trivy provides this)

If findings exist that are NOT in `.trivyignore`, STOP with FAIL. If all remaining findings are suppressed by `.trivyignore`, PASS with a summary of the suppressed count.

## Output

```
## Trivy Scan: {branch-name}

**Scanned:** {TF_PARENT}, {CHARTS_PATH}

### Findings (excluding .trivyignore suppressions)

| Severity | Rule | Title | File |
|----------|------|-------|------|
| CRITICAL | AZU-0041 | Storage account uses outdated TLS version | modules/storage/main.tf |

### Suppressed (.trivyignore)

| Rule | Justification |
|------|---------------|
| AZU-0013 | Deferred until VNet integration |

### Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 1 |
| HIGH     | 0 |
| MEDIUM   | 0 |
| LOW      | 0 (not shown; pass --strict to include) |

**Overall: PASS / FAIL**
```

## When NOT to Use

- **Runtime container scanning** — `/trivy-scan` only does IaC (`trivy config`). For image scanning (`trivy image`) use a separate CI step.
- **Policy-as-code beyond trivy's built-in rules** — for custom OPA/Rego checks, use a dedicated tool.

## Guidelines

- Never commit a `.trivyignore` entry without a justification comment.
- Periodically review `.trivyignore` — deferred items should either be resolved or have an issue tracking the work.
- Treat `CRITICAL`/`HIGH` findings as PR blockers; `MEDIUM` as must-fix-before-merge; `LOW` as advisory.
- Trivy rules occasionally target deprecated resource types (e.g. AZU-0026 is Single-Server only). Verify before suppressing — and document the reason.
