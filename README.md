# 🔧 Facebook Marketplace "Loading..." Image Upload Fix

## Chrome DevTools MCP - Fix para subida intermitente de imágenes

> **Problema:** El comando `upload_file` falla intermitentemente en Facebook Marketplace. A veces funciona, a veces no, en la misma página. La imagen se queda en "Loading..." eterno.

---

## 🐛 El Problema Detectado

```
❌ upload_file() en Facebook Marketplace → "Loading..." eterno
❌ A veces funciona, a veces no (misma página, misma ruta)
❌ Error: "The element could not accept the file directly"
```

**Diagnóstico:** Facebook usa botones que activan inputs file ocultos (`display: none`). Los 2 métodos originales del Chrome DevTools MCP no pueden subir correctamente a estos elementos ocultos.

**NOTA:** NO es por rutas complejas. Probamos y todas funcionan:
- ✅ Rutas simples: `C:\Users\user\Downloads\foto.jpg`
- ✅ Con espacios: `C:\My Documents\foto.jpg`  
- ✅ Con paréntesis: `C:\Downloads\COPIA (19-09-2025)\foto.png`
- ✅ Con caracteres unicode: `C:\Downloads\TapScanner 13꞉22 (p1).jpg`

---

## ✅ La Solución

Este fix **ELIMINA el file chooser del sistema** (que a veces no funciona) y usa Chrome DevTools Protocol directamente:

```
Método 1: handle.uploadFile()  → para inputs visibles ✅
Método 2: CDP directo          → para inputs ocultos, SIN ventana del sistema ✅
```

### ¿Por qué sin ventana del sistema?

- El file chooser nativo (ventana del sistema) **a veces no responde**
- CDP sube el archivo **directamente al input**, sin pasar por el sistema
- **Más rápido, más confiable, sin ventanas emergentes**

### Cómo funciona:

1. Intenta upload directo (funciona para inputs visibles)
2. Si falla, usa CDP para subir directamente al input file oculto
3. **NO abre ninguna ventana del sistema**

---

---

## 📦 Instalación

### Instalación Automática

Ejecuta el script para tu sistema operativo:

**Windows:**
```batch
scripts\apply-fix.bat
```

**Linux/Mac:**
```bash
chmod +x scripts/apply-fix.sh
./scripts/apply-fix.sh
```

### Instalación Manual

1. Encuentra tu instalación de chrome-devtools-mcp:
   ```bash
   npm list -g chrome-devtools-mcp
   npm root -g
   ```

2. Navega al directorio de tools:
   ```bash
   cd $(npm root -g)/chrome-devtools-mcp/build/src/tools
   ```

3. Haz backup del archivo original:
   ```bash
   cp input.js input.js.backup
   ```

4. Reemplaza el handler `uploadFile` (líneas 297-342) con la versión parcheada de `fix/input-file-patched-handler.js`

---

## ✅ Verificación

Después de aplicar el fix, prueba en Facebook Marketplace:

1. Navega a https://www.facebook.com/marketplace/create/item
2. Usa la herramienta `upload_file` directamente en el botón "Add photos or drag and drop"
3. La imagen debería subirse exitosamente

---

## 🔧 Detalles Técnicos

El handler parcheado usa CDP para subir directamente sin ventana del sistema:

```javascript
// CDP Upload - Sin ventana del sistema
const cdpSession = await page.target().createCDPSession();

// Obtener el node del input file
const { node } = await cdpSession.send('DOM.describeNode', {
    objectId: elementHandle.remoteObject.objectId
});

// Subir archivo directamente via CDP
await cdpSession.send('DOM.setFileInputFiles', {
    files: [filePath],
    backendNodeId: node.backendNodeId
});
```

---

## 📝 Notas

- **Versión probada**: Chrome DevTools MCP v0.20.3
- Este fix modifica el paquete npm global. Si actualizas chrome-devtools-mcp, tendrás que reaplicar el parche.
- El archivo backup (`input.js.backup`) se crea durante la instalación automática.

---

## 📄 Licencia

Este fix se proporciona "tal cual". El chrome-devtools-mcp original está licenciado bajo Apache-2.0.
