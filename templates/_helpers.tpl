{{/*
Expand the name of the chart.
*/}}
{{- define "diode.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "diode.fullname" -}}
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
{{- define "diode.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "diode.labels" -}}
helm.sh/chart: {{ include "diode.chart" . }}
{{ include "diode.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "diode.selectorLabels" -}}
app.kubernetes.io/name: {{ include "diode.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "diode.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "diode.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate the diode command
*/}}
{{- define "diode-command" -}}
{{- $finalCommand := "" }}
{{- range $item := .Values.cli }}
  {{- $options := "" }}
  {{- $command := "" }}
  {{- $optionList := "" }}
  {{- range $option := $item.options }}
    {{- $value := $option.value }}
    {{- $match := $value | regexMatch "(?i)localServer\\.base64PrivateKey\\..*" }}
    {{- if $match }}
      {{- $envVar := $value | upper | replace "." "_" | printf "/go/diode/%s" }}
      {{- $value = $envVar }}
    {{- end }}
    {{- $optionList = printf "%s -%s %s" $optionList $option.key $value }}
  {{- end }}
  {{- $options = printf "%s %s" $options $optionList }}
  {{- range $key, $value := $item.command }}
    {{- $command = printf "%s %s" $command $key }}
    {{- if gt (len $value) 0 }}
    {{- range $arg := $value }}
      {{- $value := $arg.value }}
      {{- $match := $value | regexMatch "(?i)localServer\\.base64PrivateKey\\..*" }}
      {{- if $match }}
        {{- $envVar := $value | upper | replace "." "_" | printf "/go/diode/%s" }}
        {{- $value = $envVar }}
      {{- end }}
      {{- $command = printf "%s -%s %s" $command $arg.key $value }}
    {{- end }}
    {{- end }}
  {{- end }}
  {{- $diodeCommand := printf "diode %s %s >/dev/null 2>&1 &" $options $command }}
  {{- $finalCommand = printf "%s %s\n" $finalCommand $diodeCommand }}
{{- end }}
{{- $finalCommand }}
{{- end }}


