{{- define "mattermost.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mattermost.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "mattermost.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
