# Instrucciones para subir el Fix a GitHub

## Opción 1: Subir el ZIP a Drive y luego a GitHub

1. **Sube el ZIP a Google Drive:**
   - Archivo: `C:\Users\jhonv\Downloads\chrome-devtools-mcp-fix.zip`
   - Ve a drive.google.com y súbelo

2. **Cuando tengas acceso a GitHub:**
   - Crea un nuevo repositorio: `chrome-devtools-mcp-fix`
   - Descarga el ZIP de Drive
   - Extrae y sube los archivos

## Opción 2: Subir directamente a GitHub (cuando tengas acceso)

```bash
# 1. Crea el repo en github.com/new
# Nombre: chrome-devtools-mcp-fix
# Descripción: Fix for file upload issues on Facebook Marketplace with Chrome DevTools MCP

# 2. En tu terminal:
cd C:\Users\jhonv\Downloads\chrome-devtools-mcp-fix

# 3. Agrega el remote (reemplaza TU_USUARIO):
git remote add origin https://github.com/TU_USUARIO/chrome-devtools-mcp-fix.git

# 4. Push:
git branch -M main
git push -u origin main
```

## Opción 3: Usar GitHub CLI (gh)

```bash
cd C:\Users\jhonv\Downloads\chrome-devtools-mcp-fix
gh repo create chrome-devtools-mcp-fix --public --source=. --push
```

## Estructura del Repositorio

```
chrome-devtools-mcp-fix/
├── README.md                              # Documentación principal
├── FIX.md                                 # Documentación técnica
├── INSTRUCCIONES_PARA_GITHUB.md           # Este archivo
├── fix/
│   └── input-file-patched-handler.js      # El código parcheado
└── scripts/
    ├── apply-fix.bat                      # Script para Windows
    └── apply-fix.sh                       # Script para Linux/Mac
```

## URLs útiles

- Crear repo nuevo: https://github.com/new
- Tu repositorio (ejemplo): https://github.com/TU_USUARIO/chrome-devtools-mcp-fix
