{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "labels.selector" -}}
app.kubernetes.io/name: {{ include "name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "labels.common" -}}
{{ include "labels.selector" . }}
app.giantswarm.io/branch: {{ .Chart.Annotations.branch | replace "#" "-" | replace "/" "-" | replace "." "-" | trunc 63 | trimSuffix "-" | quote }}
application.giantswarm.io/commit: {{ .Chart.Annotations.commit | quote }}
application.kubernetes.io/managed-by: {{ .Release.Service | quote }}
application.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
application.giantswarm.io/team: {{ index .Chart.Annotations "io.giantswarm.application.team" | quote }}
giantswarm.io/managed-by: {{ .Release.Name | quote }}
giantswarm.io/service-type: {{ .Values.serviceType }}
giantswarm.io/cluster: {{ .Values.clusterName | quote }}
helm.sh/chart: {{ include "chart" . | quote }}
{{- end -}}

{{/*
Get list of all provided OIDC domains
*/}}
{{- define "aws.oidcDomains" -}}
{{- $oidcDomains := list .Values.providers.aws.oidc.domain -}}
{{- if .Values.providers.aws.oidc.additionalDomains -}}
{{- $oidcDomains = concat $oidcDomains .Values.providers.aws.oidc.additionalDomains -}}
{{- end -}}
{{- compact $oidcDomains | uniq | toJson -}}
{{- end -}}

{{/*
Check if AWS is properly configured
*/}}
{{- define "aws.isProperlyConfigured" -}}
{{- if and .Values.providers.aws.enabled .Values.providers.aws.accountID .Values.providers.aws.region .Values.providers.aws.oidc.domain -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}

{{/*
Check if Azure is properly configured
*/}}
{{- define "azure.isProperlyConfigured" -}}
{{- if and .Values.providers.azure.enabled .Values.providers.azure.subscriptionId .Values.providers.azure.resourceGroup .Values.providers.azure.location -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}