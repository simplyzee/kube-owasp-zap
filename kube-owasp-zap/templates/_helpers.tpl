{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "kube-owasp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name, truncated to leave room for
suffixes (Job revision, CronJob-generated names).
*/}}
{{- define "kube-owasp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 40 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 40 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 40 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kube-owasp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kube-owasp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-owasp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "kube-owasp.labels" -}}
{{ include "kube-owasp.selectorLabels" . }}
helm.sh/chart: {{ include "kube-owasp.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Legacy 0.1.x values (zapcli.*) are still honoured for the target, image
and debug flag so old values files keep working.
*/}}
{{- define "kube-owasp.legacy" -}}
{{- index .Values "zapcli" | default dict | toYaml -}}
{{- end -}}

{{- define "kube-owasp.target" -}}
{{- $legacy := include "kube-owasp.legacy" . | fromYaml -}}
{{- default (index $legacy "targetHost" | default "") .Values.scan.target -}}
{{- end -}}

{{- define "kube-owasp.image" -}}
{{- $legacy := include "kube-owasp.legacy" . | fromYaml -}}
{{- $legacyImage := index $legacy "image" | default dict -}}
{{- $repo := .Values.image.repository -}}
{{- $tag := default .Chart.AppVersion .Values.image.tag -}}
{{- with index $legacyImage "repository" }}{{ $repo = . }}{{ end -}}
{{- with index $legacyImage "tag" }}{{ $tag = . }}{{ end -}}
{{- printf "%s:%s" $repo (toString $tag) -}}
{{- end -}}

{{- define "kube-owasp.pullPolicy" -}}
{{- $legacy := include "kube-owasp.legacy" . | fromYaml -}}
{{- $legacyImage := index $legacy "image" | default dict -}}
{{- default .Values.image.pullPolicy (index $legacyImage "pullPolicy") -}}
{{- end -}}

{{- define "kube-owasp.debug" -}}
{{- $legacy := include "kube-owasp.legacy" . | fromYaml -}}
{{- $legacyDebug := index $legacy "debug" | default dict -}}
{{- if or .Values.scan.debug (index $legacyDebug "enabled") }}true{{ end -}}
{{- end -}}

{{/*
Fail early with a clear message instead of a Job that errors at runtime.
*/}}
{{- define "kube-owasp.validate" -}}
{{- $target := include "kube-owasp.target" . -}}
{{- if not $target -}}
{{- fail "kube-owasp-zap: set scan.target to the URL to scan, e.g. --set scan.target=https://staging.example.com. Only scan sites you own or have permission to test." -}}
{{- end -}}
{{- if not (regexMatch "^https?://" $target) -}}
{{- fail (printf "kube-owasp-zap: scan.target %q must start with http:// or https://" $target) -}}
{{- end -}}
{{- if not (has .Values.scan.type (list "baseline" "full" "api")) -}}
{{- fail (printf "kube-owasp-zap: scan.type must be baseline, full or api (got %q)" .Values.scan.type) -}}
{{- end -}}
{{- if and (eq .Values.scan.type "api") (not (has .Values.scan.apiFormat (list "openapi" "soap" "graphql"))) -}}
{{- fail (printf "kube-owasp-zap: scan.apiFormat must be openapi, soap or graphql (got %q)" .Values.scan.apiFormat) -}}
{{- end -}}
{{- end -}}

{{/*
The shell script the scan container runs. The target comes in through an
environment variable so it is never interpreted by the shell.
*/}}
{{- define "kube-owasp.script" -}}
{{- $s := .Values.scan -}}
{{- $scripts := dict "baseline" "zap-baseline.py" "full" "zap-full-scan.py" "api" "zap-api-scan.py" -}}
{{- $reportFlags := dict "html" "-r" "json" "-J" "md" "-w" "xml" "-x" -}}
set -u
ts=$(date -u +%Y%m%d-%H%M%S)
{{- if $s.rulesConfig }}
cp /zap/config/rules.conf /zap/wrk/rules.conf
{{- end }}
set -- -t "$ZAP_TARGET"
{{- if eq $s.type "api" }}
set -- "$@" -f {{ $s.apiFormat | quote }}
{{- else }}
set -- "$@" -m {{ int $s.spiderMinutes | quote }}
{{- if $s.ajaxSpider }}
set -- "$@" -j
{{- end }}
{{- end }}
{{- range .Values.report.formats }}
set -- "$@" {{ index $reportFlags . }} "zap-$ts.{{ . }}"
{{- end }}
{{- if $s.rulesConfig }}
set -- "$@" -c rules.conf
{{- end }}
{{- if $s.includeAlpha }}
set -- "$@" -a
{{- end }}
{{- if not $s.failOnWarnings }}
set -- "$@" -I
{{- end }}
{{- if gt (int $s.maxMinutes) 0 }}
set -- "$@" -T {{ int $s.maxMinutes | quote }}
{{- end }}
{{- if include "kube-owasp.debug" . }}
set -- "$@" -d
{{- end }}
{{- with $s.zapOptions }}
set -- "$@" -z {{ . | squote }}
{{- end }}
{{- range $s.extraArgs }}
set -- "$@" {{ . | squote }}
{{- end }}
echo "Running {{ $s.type }} scan against $ZAP_TARGET"
{{ get $scripts $s.type }} "$@"
rc=$?
{{- if and .Values.report.printToLog (has "md" .Values.report.formats) }}
if [ -f "/zap/wrk/zap-$ts.md" ]; then
  echo
  echo "===== ZAP report ====="
  cat "/zap/wrk/zap-$ts.md"
fi
{{- end }}
echo
echo "Reports: $(ls /zap/wrk/zap-$ts.* 2>/dev/null | tr '\n' ' ')"
echo "Scan finished with exit code $rc (0 = clean, 1 = FAIL alerts, 2 = WARN alerts, 3 = error)"
exit $rc
{{- end -}}

{{/*
Pod spec shared by the Job and the CronJob.
*/}}
{{- define "kube-owasp.podTemplate" -}}
metadata:
  labels:
    {{- include "kube-owasp.labels" . | nindent 4 }}
    {{- with .Values.podLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if or .Values.scan.rulesConfig .Values.podAnnotations }}
  annotations:
    {{- if .Values.scan.rulesConfig }}
    checksum/rules: {{ .Values.scan.rulesConfig | sha256sum }}
    {{- end }}
    {{- with .Values.podAnnotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- end }}
spec:
  restartPolicy: Never
  automountServiceAccountToken: {{ .Values.automountServiceAccountToken }}
  {{- with .Values.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.podSecurityContext }}
  securityContext:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  containers:
    - name: zap
      image: {{ include "kube-owasp.image" . | quote }}
      imagePullPolicy: {{ include "kube-owasp.pullPolicy" . }}
      command: ["sh", "-c"]
      args:
        - |
          {{- include "kube-owasp.script" . | nindent 10 }}
      env:
        - name: ZAP_TARGET
          value: {{ include "kube-owasp.target" . | quote }}
      {{- with .Values.securityContext }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.resources }}
      resources:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      volumeMounts:
        # The ZAP scan scripts require /zap/wrk to be a mounted volume.
        - name: reports
          mountPath: /zap/wrk
        {{- if .Values.scan.rulesConfig }}
        - name: rules
          mountPath: /zap/config
          readOnly: true
        {{- end }}
  volumes:
    - name: reports
      {{- if .Values.report.persistence.enabled }}
      persistentVolumeClaim:
        claimName: {{ .Values.report.persistence.existingClaim | default (printf "%s-reports" (include "kube-owasp.fullname" .)) }}
      {{- else }}
      emptyDir: {}
      {{- end }}
    {{- if .Values.scan.rulesConfig }}
    - name: rules
      configMap:
        name: {{ include "kube-owasp.fullname" . }}-rules
    {{- end }}
  {{- with .Values.nodeSelector }}
  nodeSelector:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .Values.tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
