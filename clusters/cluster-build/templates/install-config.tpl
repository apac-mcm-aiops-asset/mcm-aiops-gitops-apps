{{- define "install-config.tpl" -}}
  apiVersion: v1
  metadata:
    name: {{ .Values.cluster }} 
  baseDomain: {{ .Values.provider.baseDomain }}
  controlPlane:
    hyperthreading: Enabled
    name: master
    replicas: {{ .Values.masters.count }}
    platform:
      vsphere:
        cpus: {{ .Values.masters.cpus }} 
        coresPerSocket:  {{ .Values.masters.coresPerSocket }}
        memoryMB:  {{ .Values.masters.memoryMB }}
        osDisk:
          diskSizeGB: {{ .Values.masters.diskGB }}
  compute:
  - hyperthreading: Enabled
    name: 'worker'
    replicas: {{ .Values.workers.count }}
    platform:
      vsphere:
        cpus: {{ .Values.workers.cpus }} 
        coresPerSocket:  {{ .Values.workers.coresPerSocket }}
        memoryMB:  {{ .Values.workers.memoryMB }}
        osDisk:
          diskSizeGB: {{ .Values.workers.diskGB }}
  platform:
    vsphere:
      vCenter: {{ .Values.provider.vcenter}} 
      username: {{ .Values.provider.username }}
      password: {{ .Values.provider.password }}
      datacenter: {{ .Values.provider.datacenter }}
      defaultDatastore: {{ .Values.provider.datastore }}
      cluster: {{ .Values.provider.vmClusterName }}
      apiVIP: {{ .Values.network.apiVIP }}
      ingressVIP: {{ .Values.network.ingressVIP }}
      network: {{ .Values.network.networkName }}
  pullSecret: "" # skip, hive will inject based on it's secrets
  sshKey: {{ .Values.provider.sshPublickey }}
{{- end }}    
