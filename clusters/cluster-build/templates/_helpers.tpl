{{- define "privateKey-embed" }}
{{- with  .Values.aws}}
{{- print " | " }}
{{- printf "%s" .sshPrivatekey  | nindent 4}}
{{- end }}
{{- end }}

{{- define "cacert-embed" }}
{{- with  .Values.provider }}
{{- print " | " }}
{{- printf "%s" .cacertificate  | nindent 4}}
{{- end }}
{{- end }}