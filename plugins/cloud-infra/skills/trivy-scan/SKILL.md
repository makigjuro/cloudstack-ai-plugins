---
name: trivy-scan
description: Scan Terraform and Helm charts for security misconfigurations using trivy. Use for a fast IaC security check — catches issues that `/infra-lint` doesn't (public-access defaults, missing encryption, weak TLS, over-broad IAM). Invoked automatically by `/infra-lint` and `/complete-infra`.
allowed-tools: Bash, Read
user-invocable: true
---

# Trivy Security Scan

Run Aqua Security's trivy against the infrastructure tree to catch misconfigurations that `terraform validate` and `helm lint` miss — things like publicly exposed storage, missing encryption, weak TLS, and over-broad IAM role assignments.

## When to Use

- **Directly (`/trivy-scan`)** — manual scan, e.g. while iterating on a module or before a PR.
- **Indirectly** — invoked from `/infra-lint` (fast check) and `/complete-infra` (pre-PR verification gate).

## Arguments

The script takes no CLI flags; the skill maps each argument to an environment variable:

- `--strict` — Run with `TRIVY_STRICT=1` (adds `LOW` to the fail set). Default: fail on `CRITICAL`, `HIGH`, `MEDIUM`; `LOW` is advisory.
- `--warn-only` — Run with `TRIVY_WARN_ONLY=1`: never exit non-zero on findings; just report. Useful for CI `continue-on-error` style gating.
- `--severity HIGH,CRITICAL` — Run with `TRIVY_SEVERITY=HIGH,CRITICAL` to override the default severity filter.

## Configuration

Read `cloudstack.json` from the project root at start of execution. Extract:
- `TF_PATH` = `infrastructure.terraformPath` (default: `infra/terraform/modules`)
- `CHARTS_PATH` = `infrastructure.chartsPath` (default: `deploy/charts`)

Derive `TF_PARENT` as the parent directory of `TF_PATH` (e.g., `infra/terraform/modules` → `infra/terraform`). If `cloudstack.json` is missing, auto-detect by scanning the project.

## Prerequisites

`trivy` must be installed locally. The skill does not auto-install — be explicit about system changes.

```bash
# macOS
brew install trivy

# Linux
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
```

If `trivy` is missing, the script prints the install command and exits 2 (even with `--warn-only`).

## Suppressing findings — `.trivyignore`

Project-local exemptions go in a `.trivyignore` file. The script uses the first one it finds, in this order: `TRIVY_IGNOREFILE` (if set and the file exists), then `{TF_PARENT}/.trivyignore`, then `.trivyignore` in the parent of `CHARTS_PATH`, then `./.trivyignore`. One rule ID per line, with a comment explaining **why**:

```
# Deferred until VNet integration (see deploy/terraform/README.md "Known limitations")
AZU-0013
AZU-0022

# Trivy check written for deprecated Single Server; we run Flexible Server
# and set TLS via `require_secure_transport` + `ssl_min_protocol_version`
AZU-0026
```

Every ignore entry must carry a justification comment. The comment is what a future reviewer uses to decide whether the suppression is still valid.

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/scan-trivy.sh` | Runs trivy against `TF_PARENT` and `CHARTS_PATH`, honouring `.trivyignore` |

The script reads `TF_PARENT` and `CHARTS_PATH` from environment variables. Export them before calling:

```bash
export TF_PARENT="..." CHARTS_PATH="..."
bash ${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/scripts/scan-trivy.sh
```

## Process

### Step 1: Run the scan

The script checks for `trivy` itself. Set the argument-mapped variables only when the corresponding argument was given:

```bash
export TF_PARENT="{TF_PARENT}" CHARTS_PATH="{CHARTS_PATH}"
# --strict:        export TRIVY_STRICT=1
# --warn-only:     export TRIVY_WARN_ONLY=1
# --severity X:    export TRIVY_SEVERITY=X
bash ${CLAUDE_PLUGIN_ROOT}/skills/trivy-scan/scripts/scan-trivy.sh
```

### Step 2: Report

Group findings by severity. For each finding, include:
- Rule ID (e.g. `AZU-0013`)
- Severity
- Title
- File:line reference
- Remediation link (trivy provides this)

If any finding is not suppressed by `.trivyignore`, report FAIL. If all remaining findings are suppressed by `.trivyignore`, PASS with a summary of the suppressed count.

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

- Periodically review `.trivyignore` — deferred items should either be resolved or have an issue tracking the work.
- Trivy rules occasionally target deprecated resource types (e.g. AZU-0026 is Single-Server only). Verify before suppressing — and document the reason.
