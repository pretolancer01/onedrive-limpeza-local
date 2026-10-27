[CmdletBinding()]
param(
    [string]$OneDrivePath = $env:OneDrive
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host '=== OneDrive e Explorador ===' -ForegroundColor Cyan
$processes = Get-Process OneDrive, explorer -ErrorAction SilentlyContinue |
    Select-Object ProcessName, Id, CPU,
        @{Name='MemoriaGB'; Expression={[math]::Round($_.WorkingSet64 / 1GB, 2)}}
if ($processes) { $processes | Format-Table -AutoSize }
else { Write-Host 'Nenhum dos processos foi encontrado.' }

Write-Host "`n=== Espaço no disco C: ===" -ForegroundColor Cyan
Get-PSDrive C | Select-Object Name,
    @{Name='LivreGB'; Expression={[math]::Round($_.Free / 1GB, 1)}},
    @{Name='UsadoGB'; Expression={[math]::Round($_.Used / 1GB, 1)}} |
    Format-Table -AutoSize

Write-Host "`n=== Pastas conhecidas do Windows ===" -ForegroundColor Cyan
$keyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
$folders = Get-ItemProperty -LiteralPath $keyPath
[pscustomobject]@{
    AreaDeTrabalho = $folders.Desktop
    Documentos     = $folders.Personal
    Imagens        = $folders.'My Pictures'
} | Format-List

if ($OneDrivePath -and (Test-Path -LiteralPath $OneDrivePath)) {
    Write-Host "Pasta sincronizada encontrada: $OneDrivePath" -ForegroundColor Green
    Write-Host 'Use o Explorador para conferir os ícones de disponibilidade. Este diagnóstico não baixa nem altera arquivos.'
} else {
    Write-Host 'Não encontrei a pasta configurada na variável OneDrive.' -ForegroundColor Yellow
}
