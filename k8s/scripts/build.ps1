[CmdletBinding()]
param(
    [string]$ImageTag = 'local',
    [string]$ImagePrefix = 'hiveapp',
    [string]$KindCluster,
    [string]$KindPath = 'kind'
)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$services = @('auth-service', 'core-service', 'delivery-service', 'visitor-service',
              'reservation-service', 'communication-service', 'event-bus', 'front')
$images = @()
foreach ($service in $services) {
    $folder = if ($service -eq 'front') { 'front' } else { "back/$service" }
    $image = "${ImagePrefix}/${service}:${ImageTag}"
    & docker build -f (Join-Path $root "$folder/docker/Dockerfile") -t $image $root
    if ($LASTEXITCODE -ne 0) { throw "Build falhou: $service" }
    $images += $image
}
if ($KindCluster) {
    & $KindPath load docker-image @images --name $KindCluster
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao carregar imagens no kind.' }
}
Write-Host "Imagens prontas: $ImageTag"
