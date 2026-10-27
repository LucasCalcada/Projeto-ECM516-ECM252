[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Kubeconfig,
    [string]$Context = 'kind-hiveapp',
    [ValidateSet('Deploy', 'Populate', 'Status')][string]$Action = 'Deploy',
    [string]$ImageTag = 'local',
    [string]$ImagePrefix = 'hiveapp',
    [switch]$ResetDevelopmentData
)
$ErrorActionPreference = 'Stop'
$kubeFile = (Resolve-Path -LiteralPath $Kubeconfig).Path
$kubeArguments = @('--kubeconfig', $kubeFile, '--context', $Context)
$overlay = (Resolve-Path (Join-Path $PSScriptRoot '../overlays/local')).Path
$services = @('auth-service', 'core-service', 'delivery-service', 'visitor-service',
              'reservation-service', 'communication-service', 'event-bus', 'front')
$jobRun = [Guid]::NewGuid().ToString('N').Substring(0, 8)
function Invoke-Kube {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & kubectl @kubeArguments @Arguments
    if ($LASTEXITCODE -ne 0) { throw "kubectl falhou: $($Arguments -join ' ')" }
}
function Get-Manifest([string]$Folder) {
    $lines = & kubectl kustomize $Folder
    if ($LASTEXITCODE -ne 0) { throw "Falha ao renderizar: $Folder" }
    $manifest = $lines -join [Environment]::NewLine
    $manifest = $manifest.Replace('hiveapp/config-checksum: local-config', "hiveapp/config-checksum: $configurationHash")
    foreach ($service in $services) {
        $manifest = $manifest.Replace("hiveapp/${service}:local", "${ImagePrefix}/${service}:${ImageTag}")
        foreach ($task in @('migrate', 'populate')) {
            $manifest = $manifest.Replace("name: ${task}-${service}", "name: ${task}-${service}-${jobRun}")
        }
    }
    return $manifest
}
function Submit-Manifest([string]$Manifest, [string]$Verb = 'apply') {
    $Manifest | & kubectl @kubeArguments $Verb -f - -o name
    if ($LASTEXITCODE -ne 0) { throw "Falha ao executar kubectl $Verb." }
}
function Wait-Jobs($Jobs) {
    foreach ($job in $Jobs) {
        Write-Host "Aguardando $job"
        try { Invoke-Kube -n hiveapp wait --for=condition=complete --timeout=210s $job }
        catch {
            Invoke-Kube -n hiveapp logs $job --all-containers=true --tail=80
            throw
        }
    }
}
if ($Action -eq 'Status') {
    Invoke-Kube -n hiveapp get 'pods,services,pvc,jobs'
    return
}
if ($Action -eq 'Populate' -and -not $ResetDevelopmentData) {
    throw 'Os scripts existentes limpam tabelas. Use -ResetDevelopmentData somente em uma base de desenvolvimento descartavel.'
}
$secretsPath = Join-Path $overlay 'secrets.env'
$secretLines = Get-Content -LiteralPath $secretsPath
foreach ($key in @('POSTGRES_USER', 'POSTGRES_PASSWORD', 'JWT_SECRET', 'INTERNAL_SECRET')) {
    $line = @($secretLines | Where-Object { $_.StartsWith("$key=") })
    if ($line.Count -ne 1 -or $line[0] -match '=($|CHANGE_ME)') { throw "Configure $key em secrets.env." }
}
# DATABASE_URL uses Kubernetes environment expansion; credentials must be URL-safe.
foreach ($line in ($secretLines | Where-Object { $_ -match '^POSTGRES_(USER|PASSWORD)=' })) {
    $value = $line.Substring($line.IndexOf('=') + 1)
    if ($value -notmatch '^[a-zA-Z0-9_-]+$') {
        throw 'Use somente letras, numeros, _ e - nas credenciais PostgreSQL.'
    }
}
# Restart applications only when their image or configuration changes.
$configuration = (Get-Content -LiteralPath $secretsPath -Raw) + (Get-Content (Join-Path $PSScriptRoot '../base/configmap.yaml') -Raw)
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $configurationHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($configuration)))).Replace('-', '').ToLowerInvariant()
} finally { $sha.Dispose() }
# Render everything before the first mutation, and never print credentials.
$infrastructure = Get-Manifest $overlay
$applications = Get-Manifest (Join-Path $overlay 'apps')
$migrations = Get-Manifest (Join-Path $overlay 'migrations')
$population = Get-Manifest (Join-Path $overlay 'populate')
Invoke-Kube cluster-info
if ($Action -eq 'Populate') {
    $jobs = @(Submit-Manifest $population 'create')
    Wait-Jobs $jobs
    return
}
Submit-Manifest $infrastructure
Invoke-Kube -n hiveapp rollout status statefulset/db --timeout=300s
Invoke-Kube -n hiveapp rollout status deployment/event-bus --timeout=180s
$jobs = @(Submit-Manifest $migrations 'create')
Wait-Jobs $jobs
Submit-Manifest $applications
foreach ($service in $services) {
    Invoke-Kube -n hiveapp rollout status "deployment/$service" --timeout=240s
}
Invoke-Kube -n hiveapp get 'pods,services,pvc'
Write-Host 'Implantacao concluida. Use port-forward do service/front para acessar.'
