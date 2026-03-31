{{- define "ghost.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ghost.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "ghost.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ghost.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "ghost.labels" -}}
helm.sh/chart: {{ include "ghost.chart" . }}
{{ include "ghost.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
organization: {{ .Values.labels.organization }}
environment: {{ .Values.labels.environment }}
appType: {{ .Values.labels.appType }}
region: {{ .Values.labels.region }}
{{- end }}

{{- define "ghost.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ghost.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
