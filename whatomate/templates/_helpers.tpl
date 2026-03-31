{{/*
Expand the name of the chart.
*/}}
{{- define "whatomate.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "whatomate.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "whatomate.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "whatomate.labels" -}}
helm.sh/chart: {{ include "whatomate.chart" . }}
{{ include "whatomate.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
organization: {{ .Values.labels.organization }}
environment: {{ .Values.labels.environment }}
appType: {{ .Values.labels.appType }}
region: {{ .Values.labels.region }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "whatomate.selectorLabels" -}}
app.kubernetes.io/name: {{ include "whatomate.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
