# Script para instalar WSL2 + Docker Desktop
# Execute como administrador (clique direito → Executar como Administrador)

Write-Host "=== Instalando WSL2 ===" -ForegroundColor Cyan
wsl --install --no-distribution
Write-Host "WSL2 instalado. Você pode ser solicitado a reiniciar.`n" -ForegroundColor Green

# Aguarda o Docker Desktop ficar pronto
Write-Host "=== Aguardando Docker Desktop ===" -ForegroundColor Cyan
Start-Sleep -Seconds 5

Write-Host "✅ Próximos passos:" -ForegroundColor Green
Write-Host "  1. Reinicie o computador (se solicitado)"
Write-Host "  2. Abra o Docker Desktop (pode levar 2–3 minutos na primeira execução)"
Write-Host "  3. Aguarde até 'Engine running' aparecer"
Write-Host "  4. Na pasta Assistente-de-Caneta/backend, execute:"
Write-Host "     > docker compose up -d"
Write-Host "     > npm install"
Write-Host "     > npm run gen:keys"
Write-Host "     > npm run db:migrate && npm run db:seed"
Write-Host "     > npm run dev"
Write-Host "`n💡 Para conferir: curl http://localhost:3000/health"
