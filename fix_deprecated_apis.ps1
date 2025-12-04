#!/usr/bin/env pwsh
# Script para corregir APIs deprecadas en Flutter

Write-Host "Corrigiendo APIs deprecadas..." -ForegroundColor Cyan

# 1. Corregir withOpacity() -> withValues(alpha: ...)
Write-Host "`n1. Reemplazando withOpacity() por withValues()..." -ForegroundColor Yellow

$files = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Reemplazar .withOpacity(X) por .withValues(alpha: X)
    $content = $content -replace '\.withOpacity\(([^)]+)\)', '.withValues(alpha: $1)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "  ✓ Actualizado: $($file.Name)" -ForegroundColor Green
    }
}

# 2. Corregir MaterialStateProperty -> WidgetStateProperty
Write-Host "`n2. Reemplazando MaterialStateProperty por WidgetStateProperty..." -ForegroundColor Yellow

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    $content = $content -replace 'MaterialStateProperty', 'WidgetStateProperty'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "  ✓ Actualizado: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✅ Correcciones completadas!" -ForegroundColor Green
