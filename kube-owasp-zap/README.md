# kube-owasp-zap

Runs [OWASP ZAP](https://www.zaproxy.org) security scans against your web apps from inside Kubernetes, as a one-off Job or on a schedule. It uses ZAP's official packaged scans and saves HTML, JSON and Markdown reports.

> **Only scan sites you own or have written permission to test.** A `full` scan sends real attack traffic.

## Install

```bash
helm repo add simplyzee https://charts.simplyzee.dev
helm repo update

helm install zap simplyzee/kube-owasp-zap \
  --namespace zap --create-namespace \
  --set scan.target=https://staging.example.com
```

Follow the scan:

```bash
kubectl logs -n zap -f job/zap-kube-owasp-zap-1
```

Run it again any time with `helm upgrade zap simplyzee/kube-owasp-zap -n zap --reuse-values`. Each upgrade creates a fresh Job, and finished Jobs are cleaned up after 7 days.

## Scan types

| `scan.type` | What it does | Where to use it |
|---|---|---|
| `baseline` (default) | Spiders the site and reports what it can see passively. No attacks. | Anywhere, including production |
| `full` | Spiders, then runs active attacks (SQL injection, XSS and more) | Test and staging environments |
| `api` | Scans an API from its OpenAPI, SOAP or GraphQL definition. Set `scan.target` to the definition URL and `scan.apiFormat` | APIs you own |

## Scheduled scans

Set a cron schedule to scan regularly. The chart then creates a CronJob instead of a Job:

```bash
helm install zap simplyzee/kube-owasp-zap -n zap \
  --set scan.target=https://staging.example.com \
  --set schedule="0 2 * * 1" \
  --set cronJob.timeZone=Europe/London \
  --set report.persistence.enabled=true
```

Trigger a run straight away with `kubectl create job -n zap --from=cronjob/zap-kube-owasp-zap zap-manual-$(date +%s)`.

## Results

- **The pod log** has ZAP's summary and, by default, the full Markdown report.
- **Job status** tells you the outcome at a glance. The Job fails when ZAP finds FAIL alerts, so you can alert on failed Jobs. Set `scan.failOnWarnings=true` to fail on WARN alerts too.
- **Report files** (`zap-<timestamp>.html`, `.json`, `.md`, `.xml`) are written to `/zap/wrk`. Enable `report.persistence` to keep them in a PersistentVolumeClaim. The claim is kept if you uninstall.

### Tuning rules

By default every alert is a WARN. Use `scan.rulesConfig` to promote rules to FAIL or ignore noise. Generate a starting file with:

```bash
docker run --rm -v "$PWD:/zap/wrk" zaproxy/zap-stable zap-baseline.py -t https://staging.example.com -g rules.conf
```

Then pass it in with `--set-file scan.rulesConfig=rules.conf`.

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `scan.target` | URL to scan (required). For `api`, the definition URL or GraphQL endpoint | `""` |
| `scan.type` | `baseline`, `full` or `api` | `baseline` |
| `scan.apiFormat` | `openapi`, `soap` or `graphql` (api scans) | `openapi` |
| `scan.spiderMinutes` | Minutes to spider (baseline and full) | `1` |
| `scan.ajaxSpider` | Also run the Ajax spider for JavaScript-heavy apps | `false` |
| `scan.includeAlpha` | Include alpha scan rules | `false` |
| `scan.failOnWarnings` | Fail the Job on WARN alerts as well as FAIL | `false` |
| `scan.maxMinutes` | Max minutes for ZAP to start and finish passive scanning (`0` = ZAP default) | `0` |
| `scan.debug` | ZAP debug output | `false` |
| `scan.rulesConfig` | Rule config (tab-separated `id`, `IGNORE`/`INFO`/`WARN`/`FAIL`, name) | `""` |
| `scan.zapOptions` | Extra ZAP options passed with `-z` | `""` |
| `scan.extraArgs` | Any other scan-script arguments | `[]` |
| `report.formats` | Any of `html`, `json`, `md`, `xml` | `[html, json, md]` |
| `report.printToLog` | Print the Markdown report to the log | `true` |
| `report.persistence.enabled` | Keep reports in a PVC | `false` |
| `report.persistence.existingClaim` | Use your own PVC | `""` |
| `report.persistence.size`, `.storageClass`, `.accessModes` | PVC settings | `1Gi`, `""`, `[ReadWriteOnce]` |
| `schedule` | Cron schedule; empty runs a single Job | `""` |
| `cronJob.timeZone` | Time zone for the schedule | `""` |
| `cronJob.concurrencyPolicy` | `Allow`, `Forbid` or `Replace` | `Forbid` |
| `cronJob.successfulJobsHistoryLimit`, `.failedJobsHistoryLimit` | Finished scans to keep | `3`, `3` |
| `cronJob.suspend` | Pause the schedule | `false` |
| `job.backoffLimit` | Retries on failure | `0` |
| `job.activeDeadlineSeconds` | Stop scans that run longer than this | `3600` |
| `job.ttlSecondsAfterFinished` | Delete finished Jobs after this many seconds (`null` keeps them) | `604800` |
| `image.repository`, `.tag`, `.pullPolicy` | ZAP image; empty tag uses `appVersion` | `zaproxy/zap-stable`, `""` (`2.17.0`), `IfNotPresent` |
| `imagePullSecrets` | Pull secrets for private registries | `[]` |
| `automountServiceAccountToken` | The scanner doesn't need the Kubernetes API | `false` |
| `podSecurityContext`, `securityContext` | Runs as non-root UID 1000, no privilege escalation, all capabilities dropped | see `values.yaml` |
| `resources` | CPU and memory | requests `250m`/`1Gi`, limit `2Gi` memory |
| `podAnnotations`, `podLabels` | Extra pod metadata | `{}` |
| `nodeSelector`, `tolerations`, `affinity` | Scheduling | `kubernetes.io/os: linux`, `[]`, `{}` |

## Upgrading from 0.1.x

- **The old `zap-cli` tool has been replaced by ZAP's packaged scans.** `zap-cli` isn't included in current ZAP images, so 0.1.x can't run with them.
- **`zapcli.targetHost`, `zapcli.image.*` and `zapcli.debug.enabled` still work.** `zapcli.scanTypes`, `zapcli.spider` and `zapcli.recursive` have no direct equivalent; use `scan.type` and `scan.spiderMinutes` instead.
- **No release-name trick needed.** You no longer need a timestamp in the release name: install once and re-run with `helm upgrade`.
- **The bundled `hofcicd-regcred` pull secret has been removed.**
