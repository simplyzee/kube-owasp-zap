# kube-owasp-zap helm chart

## Configuration

The following tables lists the configurable parameters of the kube-owasp-zap chart and their default values.

| Parameter                  | Description                         | Default                                                 |
|----------------------------|-------------------------------------|---------------------------------------------------------|
| `zapcli.image.repository`         | Zap CLI image repository | `owasp/zap2docker-stable` |
| `zapcli.image.tag`         | Zap CLI image tag | `2.8.0` |
| `zapcli.image.pullPolicy`         | Image pull policy | `IfNotPresent` |
| `zapcli.debug.enabled`         | Enable verbose mode | `false` |
| `zapcli.scanTypes`         | Vulnerability scan type | `xss, sqli` |
| `zapcli.spider.enabled`         | Enable spider | `true` |
| `zapcli.recursive.enabled`         | Enable recursive scanning | `true` |
| `zapcli.targetHost`         | URL to scan | `http://nodegoat.herokuapp.com/` |


Read through the [values.yaml](https://github.com/zee-ahmed/kube-owasp-zap/blob/master/kube-owasp-zap/values.yaml) file. It has several commented out suggested values.
