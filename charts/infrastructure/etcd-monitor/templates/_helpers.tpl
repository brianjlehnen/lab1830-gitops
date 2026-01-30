{{- define "etcd-monitor.labels" -}}
app.kubernetes.io/name: etcd-monitor
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
