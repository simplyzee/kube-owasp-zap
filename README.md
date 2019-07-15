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

This will deploy a Job that will deploy a pod on the Kubernetes platform that will perform the vulnerability scan.

## Contributing

Please raise an issue or pull request if you have any issues, questions or features.
