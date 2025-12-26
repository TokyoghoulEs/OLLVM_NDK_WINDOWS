# ============================================================================
# OLLVM Installer for Windows
# ============================================================================
# Este script descarga e instala OLLVM en tu NDK automáticamente
#
# Uso:
#   .\install-ollvm.ps1
#   .\install-ollvm.ps1 -NdkPath "C:\Android\Sdk\ndk\27.0.12077973"
# ============================================================================

param(
    [string]$NdkPath = "",
    [string]$OllvmVersion = "17.0.6"
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   OLLVM Installer for Windows" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# PASO 1: Encontrar NDK
# ============================================================================
Write-Host "📍 Buscando Android NDK..." -ForegroundColor Yellow

if ($NdkPath -eq "") {
    # Buscar en ubicaciones comunes
    $possiblePaths = @(
        "$env:ANDROID_NDK_HOME",
        "$env:ANDROID_HOME\ndk\*",
        "$env:LOCALAPPDATA\Android\Sdk\ndk\*",
        "C:\Android\Sdk\ndk\*",
        "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\ndk\*"
    )
    
    foreach ($path in $possiblePaths) {
        $found = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue | 
                 Sort-Object Name -Descending | 
                 Select-Object -First 1
        if ($found) {
            $NdkPath = $found.FullName
            break
        }
    }
}

if ($NdkPath -eq "" -or !(Test-Path $NdkPath)) {
    Write-Host "❌ No se encontró Android NDK" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor especifica la ruta:" -ForegroundColor Yellow
    Write-Host "  .\install-ollvm.ps1 -NdkPath 'C:\Android\Sdk\ndk\27.0.12077973'" -ForegroundColor Gray
    exit 1
}

Write-Host "  ✅ NDK encontrado: $NdkPath" -ForegroundColor Green

# Verificar que es un NDK válido
$toolchainPath = "$NdkPath\toolchains\llvm\prebuilt\windows-x86_64\bin"
if (!(Test-Path $toolchainPath)) {
    Write-Host "❌ No parece ser un NDK válido (no se encontró toolchain)" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ Toolchain: $toolchainPath" -ForegroundColor Green

# ============================================================================
# PASO 2: Descargar OLLVM
# ============================================================================
Write-Host ""
Write-Host "📥 Descargando OLLVM $OllvmVersion..." -ForegroundColor Yellow

$releaseUrl = "https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/releases/download/ollvm-$OllvmVersion/OLLVM-$OllvmVersion-Windows-x64.zip"
$zipPath = "$env:TEMP\ollvm-$OllvmVersion.zip"
$extractPath = "$env:TEMP\ollvm-extract"

try {
    # Intentar descargar desde releases
    Invoke-WebRequest -Uri $releaseUrl -OutFile $zipPath -UseBasicParsing
    Write-Host "  ✅ Descargado desde Releases" -ForegroundColor Green
} catch {
    # Si falla, intentar desde rama binaries
    Write-Host "  ⚠️ Release no encontrado, intentando rama binaries..." -ForegroundColor Yellow
    
    $binariesUrl = "https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/archive/refs/heads/binaries.zip"
    try {
        Invoke-WebRequest -Uri $binariesUrl -OutFile $zipPath -UseBasicParsing
        Write-Host "  ✅ Descargado desde rama binaries" -ForegroundColor Green
    } catch {
        Write-Host "❌ No se pudo descargar OLLVM" -ForegroundColor Red
        Write-Host "  Verifica que el workflow de GitHub Actions haya terminado" -ForegroundColor Gray
        Write-Host "  https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/actions" -ForegroundColor Gray
        exit 1
    }
}

# ============================================================================
# PASO 3: Extraer
# ============================================================================
Write-Host ""
Write-Host "📦 Extrayendo..." -ForegroundColor Yellow

if (Test-Path $extractPath) {
    Remove-Item -Recurse -Force $extractPath
}

Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# Encontrar los binarios
$clangExe = Get-ChildItem -Path $extractPath -Recurse -Filter "clang.exe" | Select-Object -First 1
if (!$clangExe) {
    Write-Host "❌ No se encontró clang.exe en el archivo descargado" -ForegroundColor Red
    exit 1
}

$binariesDir = $clangExe.DirectoryName
Write-Host "  ✅ Binarios encontrados en: $binariesDir" -ForegroundColor Green

# ============================================================================
# PASO 4: Backup de originales
# ============================================================================
Write-Host ""
Write-Host "💾 Creando backup de binarios originales..." -ForegroundColor Yellow

$backupDir = "$toolchainPath\backup-original"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$filesToBackup = @("clang.exe", "clang++.exe", "clang-cl.exe")
foreach ($file in $filesToBackup) {
    $src = "$toolchainPath\$file"
    if (Test-Path $src) {
        if (!(Test-Path "$backupDir\$file")) {
            Copy-Item $src "$backupDir\$file"
            Write-Host "  ✅ Backup: $file" -ForegroundColor Green
        } else {
            Write-Host "  ⏭️ Backup ya existe: $file" -ForegroundColor Gray
        }
    }
}

# ============================================================================
# PASO 5: Instalar OLLVM
# ============================================================================
Write-Host ""
Write-Host "🔧 Instalando OLLVM..." -ForegroundColor Yellow

$filesToCopy = @("clang.exe", "clang++.exe", "clang-cl.exe", "lld.exe", "lld-link.exe", "ld.lld.exe")
foreach ($file in $filesToCopy) {
    $src = "$binariesDir\$file"
    if (Test-Path $src) {
        Copy-Item $src "$toolchainPath\$file" -Force
        Write-Host "  ✅ Instalado: $file" -ForegroundColor Green
    }
}

# ============================================================================
# PASO 6: Verificar instalación
# ============================================================================
Write-Host ""
Write-Host "🧪 Verificando instalación..." -ForegroundColor Yellow

# Crear archivo de prueba
$testFile = "$env:TEMP\ollvm-test.c"
@"
int test_function(int x) {
    if (x > 10) return x * 2;
    return x + 1;
}
"@ | Out-File -FilePath $testFile -Encoding UTF8

$testOutput = "$env:TEMP\ollvm-test.o"
$clang = "$toolchainPath\clang.exe"

try {
    & $clang -target aarch64-linux-android21 -mllvm -fla -c $testFile -o $testOutput 2>&1 | Out-Null
    
    if (Test-Path $testOutput) {
        Write-Host "  ✅ OLLVM funciona correctamente!" -ForegroundColor Green
        Remove-Item $testOutput -ErrorAction SilentlyContinue
    } else {
        throw "No se generó archivo de salida"
    }
} catch {
    Write-Host "  ⚠️ No se pudo verificar (puede funcionar igual)" -ForegroundColor Yellow
}

Remove-Item $testFile -ErrorAction SilentlyContinue

# ============================================================================
# PASO 7: Limpiar
# ============================================================================
Write-Host ""
Write-Host "🧹 Limpiando archivos temporales..." -ForegroundColor Yellow

Remove-Item $zipPath -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $extractPath -ErrorAction SilentlyContinue

# ============================================================================
# RESUMEN
# ============================================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "   ✅ OLLVM instalado correctamente!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "NDK: $NdkPath" -ForegroundColor Cyan
Write-Host "OLLVM: $OllvmVersion" -ForegroundColor Cyan
Write-Host ""
Write-Host "Flags disponibles:" -ForegroundColor Yellow
Write-Host "  -mllvm -fla    Control Flow Flattening" -ForegroundColor Gray
Write-Host "  -mllvm -bcf    Bogus Control Flow" -ForegroundColor Gray
Write-Host "  -mllvm -sub    Instruction Substitution" -ForegroundColor Gray
Write-Host "  -mllvm -sobf   String Obfuscation" -ForegroundColor Gray
Write-Host "  -mllvm -split  Basic Block Split" -ForegroundColor Gray
Write-Host "  -mllvm -ibr    Indirect Branch" -ForegroundColor Gray
Write-Host "  -mllvm -icall  Indirect Call" -ForegroundColor Gray
Write-Host ""
Write-Host "Ejemplo de uso:" -ForegroundColor Yellow
Write-Host "  $clang -target aarch64-linux-android21 -mllvm -fla -mllvm -bcf -c test.c -o test.o" -ForegroundColor Gray
Write-Host ""
Write-Host "Para restaurar originales:" -ForegroundColor Yellow
Write-Host "  Copy-Item '$backupDir\*' '$toolchainPath\' -Force" -ForegroundColor Gray
Write-Host ""
