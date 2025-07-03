{{/*
Expand the name of the chart.
*/}}
{{- define "generic-app.name" -}}
{{- if .Values.app.name }}
{{- .Values.app.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "generic-app.fullname" -}}
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
{{- define "generic-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "generic-app.labels" -}}
helm.sh/chart: {{ include "generic-app.chart" . }}
{{ include "generic-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "generic-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "generic-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "generic-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "generic-app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the image name
*/}}
{{- define "generic-app.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) }}
{{- end }}

{{/*
Calculate CPU request (50% of limit)
*/}}
{{- define "generic-app.cpuRequest" -}}
{{- if hasSuffix "m" .Values.resources.cpu }}
{{- $cpu := .Values.resources.cpu | trimSuffix "m" | int }}
{{- div $cpu 2 }}m
{{- else }}
{{- $cpu := .Values.resources.cpu | float64 }}
{{- div $cpu 2 }}
{{- end }}
{{- end }}

{{/*
Calculate memory request (50% of limit)
*/}}
{{- define "generic-app.memoryRequest" -}}
{{- if hasSuffix "Mi" .Values.resources.memory }}
{{- $memory := .Values.resources.memory | trimSuffix "Mi" | int }}
{{- div $memory 2 }}Mi
{{- else if hasSuffix "Gi" .Values.resources.memory }}
{{- $memory := .Values.resources.memory | trimSuffix "Gi" | int }}
{{- $memoryMi := mul $memory 1024 }}
{{- div $memoryMi 2 }}Mi
{{- else }}
{{- .Values.resources.memory }}
{{- end }}
{{- end }}

{{/*
Validate CPU resource guardrails
*/}}
{{- define "generic-app.validateCpu" -}}
{{- $cpuValue := 0 }}
{{- if hasSuffix "m" .Values.resources.cpu }}
  {{- $cpuValue = .Values.resources.cpu | trimSuffix "m" | int }}
  {{- if or (lt $cpuValue 100) (gt $cpuValue 4000) }}
    {{- fail "Error: CPU must be between 100m and 4000m" }}
  {{- end }}
{{- else }}
  {{- $cpuValue = .Values.resources.cpu | float64 | mul 1000 }}
  {{- if or (lt $cpuValue 100) (gt $cpuValue 4000) }}
    {{- fail "Error: CPU must be between 0.1 and 4 cores" }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Validate memory resource guardrails
*/}}
{{- define "generic-app.validateMemory" -}}
{{- $memoryValue := 0 }}
{{- if hasSuffix "Mi" .Values.resources.memory }}
  {{- $memoryValue = .Values.resources.memory | trimSuffix "Mi" | int }}
  {{- if or (lt $memoryValue 128) (gt $memoryValue 8192) }}
    {{- fail "Error: Memory must be between 128Mi and 8192Mi (8Gi)" }}
  {{- end }}
{{- else if hasSuffix "Gi" .Values.resources.memory }}
  {{- $memoryValue = .Values.resources.memory | trimSuffix "Gi" | int }}
  {{- if or (lt $memoryValue 1) (gt $memoryValue 8) }}
    {{- fail "Error: Memory must be between 1Gi and 8Gi" }}
  {{- end }}
{{- else }}
  {{- fail "Error: Memory must be specified in Mi or Gi units" }}
{{- end }}
{{- end }} 