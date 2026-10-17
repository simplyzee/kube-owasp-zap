# kube-owasp-zap

kube-owasp-zap runs [OWASP ZAP](https://www.zaproxy.org) security scans from inside your Kubernetes cluster. Point it at a web app or API you own, and it runs ZAP's packaged baseline, full or API scan as a Job, or on a schedule as a CronJob. The results go to the pod log and to HTML, JSON and Markdown reports.

> Only scan sites you own or have written permission to test.

## Quick start

```bash
helm repo add simplyzee https://charts.simplyzee.dev
helm repo update

helm install zap simplyzee/kube-owasp-zap \
  --namespace zap --create-namespace \
  --set scan.target=https://staging.example.com

kubectl logs -n zap -f job/zap-kube-owasp-zap-1
```

Run the scan again with `helm upgrade zap simplyzee/kube-owasp-zap -n zap --reuse-values`. To install from this repo instead, use `./kube-owasp-zap` in place of `simplyzee/kube-owasp-zap`.

Scan types, scheduling, reports, rule tuning and every setting are covered in the [chart README](kube-owasp-zap/README.md).

## What's in 0.2.0

- **Works with current ZAP.** It uses the official `zaproxy/zap-stable` image (2.17.0) and ZAP's packaged scans. The old `zap-cli` isn't shipped in ZAP images any more.
- **Three scan types:** a passive `baseline` (the default, and safe for production), an active `full` scan, and an `api` scan from OpenAPI, SOAP or GraphQL definitions.
- **Scheduled scans:** set `schedule` to get a CronJob, with time zone support.
- **Reports:** HTML, JSON, Markdown and XML, with the Markdown report printed to the log and optional persistence to a volume.
- **Clear results:** the Job fails when ZAP finds FAIL alerts (optionally WARN too), so you can alert on it. Rules can be tuned with a config file.
- **Easy re-runs:** `helm upgrade` creates a fresh Job, and old Jobs clean themselves up.
- **Locked down:** runs as non-root, no privilege escalation, all capabilities dropped, and no Kubernetes API token.
- **Safer defaults:** no default target, and clear errors for missing or invalid settings. The bundled private pull secret is gone.
- **CI:** strict lint, schema validation, shell checks of the scan script, and a real scan in a throwaway kind cluster on every change.

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.
