{{- define "telemetry-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "telemetry-stack.labels" -}}
app.kubernetes.io/name: {{ include "telemetry-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "telemetry-stack.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "telemetry-stack.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
