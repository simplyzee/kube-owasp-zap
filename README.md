# kube-owasp-zap

## Introduction

kube-owasp-zap is an owasp-zap solution for Kubernetes. It allows you to perform a vulnerability analysis on a host using Kubernetes as the platform. It creates a Job that deploys a pod that will scan the host for any vulnerabilities.

## Setup
The setup guide will help you perform an owasp-zap scan using Kubernetes.

1. Deploy the kube-owasp-zap chart with the values set for type of scan and target host

```bash
> helm install ./kube-owasp-zap --name vuln-scan \
    --namespace owasp-zap \
    --set zapcli.debug.enabled=true \
    --set zapcli.spider.enabled=true \
    --set zapcli.recursive.enabled=true \
    --set zapcli.targetHost=[ URL to scan ]
```

2. Deploy using Helm repository

```bash
helm repo add simplyzee https://charts.simplyzee.dev
helm install simplyzee/kube-owasp-zap --name vuln-scan \
    --namespace owasp-zap \
    --set zapcli.debug.enabled=true \
    --set zapcli.spider.enabled=true \
    --set zapcli.recursive.enabled=true \
    --set zapcli.targetHost=[ URL to scan ]
```

This will deploy a Job that will deploy a pod on the Kubernetes platform that will perform the vulnerability scan.

## Roadmap
Still ALOT of work around platform improvements with Kubernetes but it utilises the Kubernetes platform well to scan sites from a vulnerability analysis perspective. 

Ideas to implement:
* Easier way of viewing scanning analysis
* Zap CLI to be more configurable as a tool on the k8s platform

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.
