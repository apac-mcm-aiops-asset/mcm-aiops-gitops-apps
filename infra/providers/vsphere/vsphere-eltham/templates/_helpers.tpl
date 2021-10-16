{{- define "metadata.vsphere" }}
{{- with .Values.provider }}
{{- print " " }}
{{- printf "username: %s\npassword: %s\nvcenter: %s\ncacertificate: '%s'\nvmClusterName: %s\ndatacenter: %s\ndatastore: %s\nbaseDomain: %s\npullSecret: '%s'\nsshPrivatekey: '%s'\nsshPublickey: '%s'"   .username .password .vcenter .cacertificate .vmClusterName .datacenter .datastore .baseDomain .pullSecret .sshPrivatekey .sshPublickey |  b64enc }}
{{- end }}
{{- end }}