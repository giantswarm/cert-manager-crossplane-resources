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
application.giantswarm.io/team: {{ index .Chart.Annotations "application.giantswarm.io/team" | quote }}
giantswarm.io/managed-by: {{ .Release.Name | quote }}
giantswarm.io/service-type: {{ .Values.serviceType }}
giantswarm.io/cluster: {{ .Values.clusterName | quote }}
helm.sh/chart: {{ include "chart" . | quote }}
{{- end -}}

{{/*
Get list of all allowed Route53 record name patterns for ACME challenges
*/}}
{{- define "aws.resourcePatterns" -}}
{{- compact .Values.providers.aws.resourcePatterns | uniq | toJson -}}
{{- end -}}

{{/*
Get the AWS account ID, partition, and OIDC domains. If `providers.aws.accountID`, `providers.aws.partition`, or
`providers.aws.oidc.domain` is empty, read the missing values from the `<clusterName>-crossplane-config` ConfigMap,
which aws-resolver-rules-operator creates once the cluster is provisioned. Explicitly set values take precedence over
the ConfigMap.
*/}}
{{- define "aws.values" -}}
{{- $aws := .Values.providers.aws -}}
{{- $ret := dict "accountID" $aws.accountID "partition" $aws.partition -}}
{{- $primaryOidcDomains := list $aws.oidc.domain -}}
{{- $configMapName := printf "%s-crossplane-config" .Values.clusterName -}}
{{- if or (not $aws.accountID) (not $aws.partition) (not $aws.oidc.domain) -}}
{{- $configMap := lookup "v1" "ConfigMap" .Release.Namespace $configMapName -}}
{{- if not $configMap -}}
{{- fail (printf "ConfigMap %s/%s not found" .Release.Namespace $configMapName) -}}
{{- end -}}
{{- if not $configMap.data.values -}}
{{- fail (printf "ConfigMap %s/%s does not contain values" .Release.Namespace $configMapName) -}}
{{- end -}}
{{- $crossplaneConfig := $configMap.data.values | fromYaml -}}
{{- if not $aws.accountID -}}
{{- $_ := set $ret "accountID" $crossplaneConfig.accountID -}}
{{- end -}}
{{- if not $aws.partition -}}
{{- $_ := set $ret "partition" $crossplaneConfig.awsPartition -}}
{{- end -}}
{{- if not $aws.oidc.domain -}}
{{- $primaryOidcDomains = $crossplaneConfig.oidcDomains | default list -}}
{{- end -}}
{{- end -}}
{{- $_ := set $ret "oidcDomains" (concat $primaryOidcDomains ($aws.oidc.additionalDomains | default list) | compact | uniq) -}}
{{- if or (not $ret.accountID) (not $ret.partition) (not $ret.oidcDomains) -}}
{{- fail (printf "AWS account ID, partition, and OIDC domains must be set in `providers.aws` or in the ConfigMap %s/%s" .Release.Namespace $configMapName) -}}
{{- end -}}
{{- $ret | toJson -}}
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

{{/*
Determine the resource group name to use.
*/}}
{{- define "azure.resourceGroupName" -}}
{{ .Values.providers.azure.resourceGroup | default .Values.clusterName }}
{{- end -}}
