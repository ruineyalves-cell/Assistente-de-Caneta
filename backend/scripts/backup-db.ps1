# backup-db.ps1 — snapshot do Postgres Recorpo (Passo 1, versao Windows).
#
# Uso no PowerShell:
#   1) Pega a EXTERNAL Database URL no dashboard Render:
#      https://dashboard.render.com/d/<seu-id>/info
#   2) $env:DATABASE_URL = "postgresql://user:pass@ohio-postgres.render.com/recorpo?sslmode=require"
#   3) .\backend\scripts\backup-db.ps1
#
# Requer pg_dump instalado. Se nao tiver:
#   winget install -e --id PostgreSQL.PostgreSQL.16
#   (ou baixar em https://www.postgresql.org/download/windows/)
#
# Restore:
#   pg_restore --clean --if-exists -d $env:DATABASE_URL backups\recorpo_XXXX.dump

$ErrorActionPreference = "Stop"

if (-not $env:DATABASE_URL) {
    Write-Host "ERRO: DATABASE_URL nao definida. Pegue a External URL no dashboard Render."
    exit 1
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$destDir = Join-Path $PSScriptRoot "..\..\backups"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }

$dumpFile = Join-Path $destDir "recorpo_$stamp.dump"
$sqlFile = Join-Path $destDir "recorpo_$stamp.sql"

Write-Host "-> Backup em formato custom..."
& pg_dump --format=custom --file=$dumpFile $env:DATABASE_URL
if ($LASTEXITCODE -ne 0) { throw "pg_dump falhou" }

Write-Host "-> Backup em SQL simples..."
& pg_dump --format=plain --file=$sqlFile $env:DATABASE_URL
if ($LASTEXITCODE -ne 0) { throw "pg_dump falhou" }

Write-Host ""
Write-Host "OK Backup pronto em $destDir"
Get-ChildItem "$destDir\recorpo_$stamp.*"
Write-Host ""
Write-Host "GUARDE ESSES ARQUIVOS FORA DO PC (Google Drive / iCloud / pendrive)."
