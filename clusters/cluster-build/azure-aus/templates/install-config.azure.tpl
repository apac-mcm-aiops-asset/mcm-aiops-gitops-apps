{{- define "install-config.azure.tpl" }}
apiVersion: v1
metadata:
  name: '{{ .Values.cluster }}'
baseDomain: {{ .Values.provider.baseDomain }} 
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: 3
  platform:
    azure:
      osDisk:
        diskSizeGB: {{ .Values.masters.diskSize }} 
      type:  {{ .Values.masters.machineType }}
compute:
- hyperthreading: Enabled
  name: 'worker'
  replicas: 3
  platform:
    azure:
      type:  {{ .Values.workers.machineType }}
      osDisk:
        diskSizeGB: {{ .Values.workers.diskSize }}
      zones:
      - "1"
      - "2"
      - "3"
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineCIDR: 10.0.0.0/16
  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  azure:
    baseDomainResourceGroupName: {{ .Values.provider.resource_group }} 
    region: {{ .Values.provider.region }} 
pullSecret: "" # skip, hive will inject based on it's secrets
sshKey: |-
   {{ .Values.provider.sshPublickey }}
{{- end }}