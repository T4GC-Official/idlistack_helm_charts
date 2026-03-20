{{- define "ghost.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ghost.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "ghost.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ghost.labels" -}}
app.kubernetes.io/name: ghost
app.kubernetes.io/instance: {{ .Release.Name }}
organization: {{ .Values.labels.organization }}
environment: {{ .Values.labels.environment }}
appType: {{ .Values.labels.appType }}
region: {{ .Values.labels.region }}
{{- end }}
