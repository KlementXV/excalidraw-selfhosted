{{/* Chart name. */}}
{{- define "excalidraw.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Release full name. Components add their suffix, so keep room for it. */}}
{{- define "excalidraw.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 50 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 50 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 50 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/* Labels. Call with (dict "ctx" $ "component" "front"). */}}
{{- define "excalidraw.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .ctx.Chart.Name .ctx.Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "excalidraw.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .ctx.Release.Service }}
{{- end }}

{{- define "excalidraw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "excalidraw.name" .ctx }}
app.kubernetes.io/instance: {{ .ctx.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end }}

{{/* Fields shared by every pod spec. */}}
{{- define "excalidraw.podSpec" -}}
automountServiceAccountToken: false
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/* Pod security context. Call with the uid. */}}
{{- define "excalidraw.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: {{ . }}
runAsGroup: {{ . }}
fsGroup: {{ . }}
seccompProfile:
  type: RuntimeDefault
{{- end }}

{{- define "excalidraw.securityContext" -}}
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop: ["ALL"]
{{- end }}

{{/* Host of publicUrl, without the port. */}}
{{- define "excalidraw.host" -}}
{{- $url := required "publicUrl is required" .Values.publicUrl | urlParse }}
{{- required "publicUrl must be a full URL, such as https://excalidraw.example.com" (get $url "host" | splitList ":" | first) }}
{{- end }}

{{/* publicUrl without its trailing slash. */}}
{{- define "excalidraw.publicUrl" -}}
{{- trimSuffix "/" .Values.publicUrl }}
{{- end }}

{{/* Full URL of the store. The front's nginx does not use the DNS search domains. */}}
{{- define "excalidraw.storageUrl" -}}
{{- printf "http://%s-storage.%s.svc.%s:8080" (include "excalidraw.fullname" .) .Release.Namespace .Values.clusterDomain }}
{{- end }}

{{/* Image: global.imageRegistry, else image.registry. Call with (dict "ctx" $ "image" .Values.front.image "tag" "x"). */}}
{{- define "excalidraw.image" -}}
{{- $g := .ctx.Values.global | default dict }}
{{- printf "%s/%s:%s" (trimSuffix "/" ($g.imageRegistry | default .image.registry)) .image.repository (.tag | default .image.tag) }}
{{- end }}

{{/* Front image. Its tag defaults to the chart appVersion. */}}
{{- define "excalidraw.frontImage" -}}
{{- include "excalidraw.image" (dict "ctx" . "image" .Values.front.image "tag" (.Values.front.image.tag | default .Chart.AppVersion)) }}
{{- end }}
