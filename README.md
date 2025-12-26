# 🔒 OLLVM NDK Builder para Windows

Este repositorio contiene un workflow de GitHub Actions que compila automáticamente LLVM con passes de OLLVM (Obfuscator-LLVM) y lo integra en un Android NDK para Windows.

## 🚀 Cómo usar

### 1. Crear tu repositorio

1. Crea un nuevo repositorio en GitHub (puede ser privado)
2. Copia la carpeta `.github/` a tu repositorio
3. Haz push

### 2. Ejecutar el workflow

1. Ve a la pestaña **Actions** de tu repositorio
2. Selecciona **"Build OLLVM NDK for Windows"**
3. Click en **"Run workflow"**
4. Configura las opciones:
   - **LLVM Version**: `17.0.6` (recomendado) o `18.1.8`
   - **NDK Version**: `r27c` (recomendado)
   - **Build Type**: `Release` o `MinSizeRel`
5. Click en **"Run workflow"**

### 3. Esperar y descargar

- ⏱️ El build toma **2-3 horas**
- 📦 Al terminar, descarga el artifact desde la pestaña Actions
- 📁 Obtendrás un NDK completo con OLLVM integrado

## 📋 Requisitos

- Cuenta de GitHub (gratis)
- Repositorio público o privado
- No necesitas nada instalado localmente

## 🔧 Flags de OLLVM disponibles

| Flag | Descripción |
|------|-------------|
| `-mllvm -fla` | Control Flow Flattening - Aplana el flujo de control |
| `-mllvm -bcf` | Bogus Control Flow - Añade código falso |
| `-mllvm -bcf_prob=N` | Probabilidad de BCF (1-100, default 70) |
| `-mllvm -bcf_loop=N` | Repeticiones de BCF (default 2) |
| `-mllvm -sub` | Instruction Substitution - Reemplaza instrucciones |
| `-mllvm -sub_loop=N` | Repeticiones de SUB (default 1) |
| `-mllvm -sobf` | String Obfuscation - Ofusca strings |
| `-mllvm -split` | Basic Block Split - Divide bloques |
| `-mllvm -split_num=N` | Número de splits (default 3) |
| `-mllvm -ibr` | Indirect Branch - Saltos indirectos |
| `-mllvm -icall` | Indirect Call - Llamadas indirectas |
| `-mllvm -igv` | Indirect Global Variable - Variables globales indirectas |

## 📝 Uso después de descargar

### Con CMake (Android Studio)

```cmake
# En tu CMakeLists.txt
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -mllvm -fla -mllvm -bcf -mllvm -sub")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mllvm -fla -mllvm -bcf -mllvm -sub")
```

### Con dex2c

```json
{
    "ndk_dir": "C:/path/to/OLLVM-NDK-r27c",
    "ollvm": {
        "enable": true,
        "flags": "-mllvm -fla -mllvm -bcf -mllvm -sub -mllvm -sobf"
    }
}
```

### Con ndk-build

```makefile
# En tu Android.mk
LOCAL_CFLAGS += -mllvm -fla -mllvm -bcf -mllvm -sub
LOCAL_CPPFLAGS += -mllvm -fla -mllvm -bcf -mllvm -sub
```

## ⚠️ Notas importantes

1. **Tiempo de compilación**: El código ofuscado tarda más en compilar
2. **Tamaño del binario**: El código ofuscado es más grande
3. **Rendimiento**: Puede haber una pequeña penalización de rendimiento
4. **Debugging**: El código ofuscado es muy difícil de debuggear

## 🔄 Versiones soportadas

| LLVM | Estado | Notas |
|------|--------|-------|
| 17.0.6 | ✅ Recomendado | Estable, bien probado |
| 18.1.8 | ⚠️ Experimental | Puede requerir ajustes |

| NDK | Estado | Notas |
|-----|--------|-------|
| r27c | ✅ Recomendado | Última LTS |
| r26d | ✅ Soportado | Estable |
| r25c | ✅ Soportado | Antiguo pero funcional |

## 📊 Recursos de GitHub Actions

- **RAM**: 16 GB (suficiente para compilar LLVM)
- **CPU**: 4 cores
- **Disco**: 14 GB disponibles
- **Tiempo máximo**: 6 horas por job
- **Costo**: Gratis para repos públicos, 2000 min/mes para privados

## 🐛 Solución de problemas

### El build falla por timeout
- Reduce los targets: cambia `AArch64;ARM;X86` a solo `AArch64;ARM`
- Usa `MinSizeRel` en lugar de `Release`

### El build falla por memoria
- Reduce el paralelismo: cambia `-j 4` a `-j 2`

### Los flags de OLLVM no funcionan
- Verifica que usaste el clang del NDK modificado
- Asegúrate de usar `-mllvm` antes de cada flag

## 📜 Licencia

- LLVM: Apache License 2.0
- OLLVM Passes: MIT License

## 🙏 Créditos

- [LLVM Project](https://llvm.org/)
- [DreamSoule/ollvm17](https://github.com/DreamSoule/ollvm17)
- [obfuscator-llvm](https://github.com/obfuscator-llvm/obfuscator)
