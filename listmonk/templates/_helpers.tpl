{{- define "listmonk.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "listmonk.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "listmonk.name" .) -}}
{{- end }}
