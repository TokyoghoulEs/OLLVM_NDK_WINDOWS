# 🔒 OLLVM NDK Builder para Windows

Compilador Clang con **OLLVM (Obfuscator-LLVM)** para ofuscar código nativo en Android.

[![Build OLLVM](https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/actions/workflows/build-ollvm-ndk.yml/badge.svg)](https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/actions/workflows/build-ollvm-ndk.yml)

---

## 📥 Descargar

### Opción 1: Releases (Recomendado)
👉 [**Descargar última versión**](https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/releases/latest)

### Opción 2: Rama binaries
👉 [**Ver binarios**](https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/tree/binaries)

---

## 🚀 Instalación Rápida

### Paso 1: Descargar NDK oficial de Google

```powershell
# Descargar NDK r27c desde:
# https://developer.android.com/ndk/downloads

# O con Android Studio:
# SDK Manager → SDK Tools → NDK (Side by side)
```

### Paso 2: Descargar binarios de OLLVM

Descarga `OLLVM-17.0.6-Windows-x64.zip` desde [Releases](https://github.com/TokyoghoulEs/OLLVM_NDK_WINDOWS/releases)

### Paso 3: Integrar en NDK

```powershell
# Ruta del NDK (ajustar según tu instalación)
$NDK = "C:\Android\Sdk\ndk\27.0.12077973"
$TOOLCHAIN = "$NDK\toolchains\llvm\prebuilt\windows-x86_64\bin"

# Hacer backup de originales
Copy-Item "$TOOLCHAIN\clang.exe" "$TOOLCHAIN\clang.exe.backup"
Copy-Item "$TOOLCHAIN\clang++.exe" "$TOOLCHAIN\clang++.exe.backup"

# Extraer y copiar binarios de OLLVM
Expand-Archive -Path "OLLVM-17.0.6-Windows-x64.zip" -DestinationPath "ollvm-temp"
Copy-Item "ollvm-temp\clang.exe" "$TOOLCHAIN\" -Force
Copy-Item "ollvm-temp\clang++.exe" "$TOOLCHAIN\" -Force

# Limpiar
Remove-Item -Recurse "ollvm-temp"

Write-Host "✅ OLLVM instalado en NDK"
```

### Paso 4: Verificar instalación

```powershell
# Crear archivo de prueba
@"
int secret(int x) {
    if (x > 10) return x * 2;
    return x + 1;
}
"@ | Out-File -FilePath "test.c" -Encoding UTF8

# Compilar con OLLVM
$CLANG = "C:\Android\Sdk\ndk\27.0.12077973\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"
& $CLANG -target aarch64-linux-android21 -mllvm -fla -mllvm -bcf -c test.c -o test.o

# Si no hay errores, OLLVM funciona!
```

---

## 🔧 Flags de Ofuscación

| Flag | Descripción | Impacto |
|------|-------------|---------|
| `-mllvm -fla` | **Control Flow Flattening** - Aplana el flujo de control | ⭐⭐⭐ Alto |
| `-mllvm -bcf` | **Bogus Control Flow** - Añade código falso | ⭐⭐⭐ Alto |
| `-mllvm -bcf_prob=N` | Probabilidad de BCF (1-100, default 70) | - |
| `-mllvm -bcf_loop=N` | Repeticiones de BCF (default 2) | - |
| `-mllvm -sub` | **Instruction Substitution** - Reemplaza instrucciones | ⭐⭐ Medio |
| `-mllvm -sub_loop=N` | Repeticiones de SUB (default 1) | - |
| `-mllvm -sobf` | **String Obfuscation** - Ofusca strings | ⭐⭐ Medio |
| `-mllvm -split` | **Basic Block Split** - Divide bloques | ⭐ Bajo |
| `-mllvm -split_num=N` | Número de splits (default 3) | - |
| `-mllvm -ibr` | **Indirect Branch** - Saltos indirectos | ⭐⭐ Medio |
| `-mllvm -icall` | **Indirect Call** - Llamadas indirectas | ⭐⭐ Medio |
| `-mllvm -igv` | **Indirect Global Variable** | ⭐ Bajo |

### Combinaciones recomendadas

```bash
# Protección MÁXIMA (más lento de compilar)
-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf -mllvm -split -mllvm -ibr -mllvm -icall

# Protección ALTA (buen balance)
-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf

# Protección MEDIA (rápido)
-mllvm -fla -mllvm -sub

# Solo strings
-mllvm -sobf
```

---

## 📝 Uso con CMake (Android Studio)

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.18)
project(MySecureApp)

# Flags de OLLVM para código crítico
set(OLLVM_FLAGS "-mllvm -fla -mllvm -bcf -mllvm -sub")

# Aplicar a todo el proyecto
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OLLVM_FLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OLLVM_FLAGS}")

add_library(native-lib SHARED native-lib.cpp)
```

### Solo para archivos específicos

```cmake
# Ofuscar solo archivos críticos
set_source_files_properties(
    security.cpp
    crypto.cpp
    license.cpp
    PROPERTIES COMPILE_FLAGS "-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf"
)
```

---

## 📝 Uso con ndk-build

### Android.mk

```makefile
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := native-lib
LOCAL_SRC_FILES := native-lib.cpp

# Flags de OLLVM
LOCAL_CFLAGS += -mllvm -fla -mllvm -bcf -mllvm -sub
LOCAL_CPPFLAGS += -mllvm -fla -mllvm -bcf -mllvm -sub

include $(BUILD_SHARED_LIBRARY)
```

---

## 📝 Uso con dex2c

### dcc.cfg

```json
{
    "apktool": "tools/apktool.jar",
    "ndk_dir": "C:/Android/Sdk/ndk/27.0.12077973",
    "signature": {
        "keystore_path": "keystore/release.keystore",
        "alias": "mykey",
        "keystore_pass": "password",
        "store_pass": "password"
    },
    "ollvm": {
        "enable": true,
        "flags": "-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf"
    }
}
```

---

## 🔨 Compilar tú mismo

Si quieres compilar OLLVM tú mismo:

1. **Fork** este repositorio
2. Ve a **Actions** → **Build OLLVM Clang for Windows**
3. Click **Run workflow**
4. Selecciona versión de LLVM (17.0.6 recomendado)
5. Espera 2-3 horas
6. Descarga desde **Releases** o rama **binaries**

---

## ⚠️ Notas importantes

### Rendimiento
- El código ofuscado es **más lento** de compilar
- El binario resultante es **más grande**
- Puede haber **pequeña penalización** de rendimiento en runtime

### Debugging
- El código ofuscado es **muy difícil** de debuggear
- Usa ofuscación solo en **builds de release**
- Mantén builds de debug sin ofuscación

### Compatibilidad
- ✅ Android NDK r25+
- ✅ AArch64 (arm64-v8a)
- ✅ ARM (armeabi-v7a)
- ❌ x86/x86_64 (no incluido para reducir tamaño)

---

## 📊 Comparación: Código normal vs OLLVM

### Código original
```c
int check_license(int key) {
    if (key == 12345) {
        return 1;  // Valid
    }
    return 0;  // Invalid
}
```

### Después de OLLVM (-fla -bcf)
El código se transforma en un switch gigante con estados, bloques falsos y predicados opacos. Ejemplo simplificado:

```c
int check_license(int key) {
    int state = 0;
    int result;
    while (1) {
        switch (state) {
            case 0:
                if ((x * x) % 2 == 0) {  // Predicado opaco (siempre true)
                    state = 1;
                } else {
                    state = 5;  // Código falso
                }
                break;
            case 1:
                if (key == 12345) {
                    state = 2;
                } else {
                    state = 3;
                }
                break;
            case 2:
                result = 1;
                state = 4;
                break;
            case 3:
                result = 0;
                state = 4;
                break;
            case 4:
                return result;
            case 5:
                // Código falso que nunca se ejecuta
                result = key ^ 0xDEAD;
                state = 3;
                break;
        }
    }
}
```

---

## 🙏 Créditos

- [LLVM Project](https://llvm.org/) - Compilador base
- [DreamSoule/ollvm17](https://github.com/DreamSoule/ollvm17) - Passes de OLLVM para LLVM 17
- [obfuscator-llvm](https://github.com/obfuscator-llvm/obfuscator) - Proyecto OLLVM original

---

## 📜 Licencia

- LLVM: Apache License 2.0
- OLLVM Passes: MIT License
- Este repositorio: MIT License

---

## 🐛 Problemas conocidos

### Error: "unknown argument: '-mllvm'"
**Causa**: Estás usando el clang original, no el de OLLVM
**Solución**: Verifica que copiaste los binarios correctamente

### Error: Compilación muy lenta
**Causa**: Los passes de ofuscación son costosos
**Solución**: Reduce flags o aplica solo a archivos críticos

### Error: APK muy grande
**Causa**: Código ofuscado es más grande
**Solución**: Usa `-Os` para optimizar tamaño, o reduce flags de ofuscación

---

**Creado por**: TokyoghoulEs  
**Última actualización**: Diciembre 2025
