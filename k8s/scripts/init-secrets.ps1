[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$destination = Join-Path $PSScriptRoot '../overlays/local/secrets.env'
if (Test-Path -LiteralPath $destination) {
    Write-Host 'secrets.env ja existe; valores preservados.'
    return
}
function New-HexSecret {
    $bytes = New-Object byte[] 32
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return ([BitConverter]::ToString($bytes)).Replace('-', '').ToLowerInvariant()
}
$values = @(
    'POSTGRES_USER=hiveapp'
    "POSTGRES_PASSWORD=$(New-HexSecret)"
    "JWT_SECRET=$(New-HexSecret)"
    "INTERNAL_SECRET=$(New-HexSecret)"
)
[IO.File]::WriteAllLines($destination, $values, [Text.UTF8Encoding]::new($false))
Write-Host 'Segredos locais criados em k8s/overlays/local/secrets.env (ignorado pelo Git).'
