# kube-owasp-zap

## Introduction

kube-owasp-zap is an owasp-zap solution for Kubernetes. It allows you to perform a vulnerability analysis on a host using Kubernetes as the platform. It creates a Job that deploys a pod that will scan the host for any vulnerabilities.

## Setup

The following shows how to perform an owasp-zap scan using Kubernetes. There are two ways to deploy. Either use this Github project (Option A) or use a Helm repository (Option B) which is a little easier.

This project runs the owasp-zap tool as a Kubernetes job. Each job needs to have a unique name. That's why the name is uniquified using a timestamp.

Kubernetes jobs are not automatically reaped so that you can still see their logs when they are complete. It this case, that is good because the result of the owasp-zap scan are in the logs.

### Prequisite

* Create a namespace.

```bash
kubectl apply -f -<<EOF
apiVersion: v1
kind: Namespace
metadata:
    name: owasp-zap
    labels:
        name: owasp-zap
EOF
```

* Assign the URL to scan. Since ibm.com is used, the spidering and recursive scanning has been turned off.

```bash
export URL_TO_SCAN="http://www.ibm.com"
```

### Option A - Deploy With GibHub Project

* Deploy the kube-owasp-zap chart with the values set for type of scan and target host.

```bash
> helm install "vuln-scan-$(date '+%Y-%m-%d-%H-%M-%S')-job" ./kube-owasp-zap \
    --namespace owasp-zap \
    --set zapcli.debug.enabled=true \
    --set zapcli.spider.enabled=false \
    --set zapcli.recursive.enabled=false \
    --set zapcli.targetHost=$URL_TO_SCAN
```

### Option B - Using Using Helm

* Add the Helm repository. Then install the chart.

```bash
> helm repo add simplyzee https://charts.simplyzee.dev

> helm install "vuln-scan-$(date '+%Y-%m-%d-%H-%M-%S')-job" implyzee/kube-owasp-zap \
    --namespace owasp-zap \
    --set zapcli.debug.enabled=true \
    --set zapcli.spider.enabled=false \
    --set zapcli.recursive.enabled=false \
    --set zapcli.targetHost=$URL_TO_SCAN
```

This will deploy a Job that will deploy a pod on the Kubernetes platform that will perform the vulnerability scan.

## Example of Job Output

* Use the following command to view the list of jobs. Since the job names have a timestamp, we can use `sort` to force newer jobs to the end of the list.

```bash
> kubectl get jobs --namespace owasp-zap | grep -v "COMPLETIONS" | sort
vuln-scan-2020-03-20-11-10-17-job-kube-owasp-zap   1/1           22s        6m53s
vuln-scan-2020-03-20-10-46-14-job-kube-owasp-zap   1/1           33s        30m
```

* Use the following command to view the logs of a job.

```bash
> kubectl logs jobs/vuln-scan-2020-03-20-11-10-17-job-kube-owasp-zap --namespace owasp-zap
[INFO]            Starting ZAP daemon
[DEBUG]           Starting ZAP process with command: /zap/zap.sh -daemon -port 8080 -config api.disablekey=true.
[DEBUG]           Logging to /zap/zap.log
[DEBUG]           ZAP started successfully.
[INFO]            Running a quick scan for https://www.ibm.com
[DEBUG]           Disabling all current scanners
[DEBUG]           Enabling scanners with IDs 40012,40014,40016,40017,40018
[DEBUG]           Scanning target https://www.ibm.com...
[DEBUG]           Started scan with ID 0...
[DEBUG]           Scan progress %: 0
[DEBUG]           Scan #0 completed
[INFO]            Issues found: 0
[INFO]            Shutting down ZAP daemon
[DEBUG]           Shutting down ZAP.
[DEBUG]           ZAP shutdown successfully.
```

## Roadmap

Still a lot of work around platform improvements with Kubernetes but it utilises the Kubernetes platform well to scan sites from a vulnerability analysis perspective. 

Ideas to implement:
* Easier way of viewing scanning analysis
* Zap CLI to be more configurable as a tool on the k8s platform

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.
