# @playwright/mcp - File Upload Fix for Facebook Marketplace

## Problema

El comando `browser_file_upload` falla en Facebook Marketplace y sitios similares que bloquean el file chooser nativo del navegador.

### Síntoma
```
❌ browser_file_upload(["ruta/imagen.jpg"]) → "No file chooser visible"
```

### Causa Raíz

El handler original de `files.js` depende del evento `filechooser` de Playwright para crear un modal state y luego llamar `setFiles()`. Pero Facebook Marketplace **bloquea la apertura del file chooser nativo** al hacer clic en "Add photos", así que Playwright nunca dispara el evento `filechooser` y el handler falla inmediatamente.

### Flujo Original (ROTO)
```
browser_file_upload(["imagen.jpg"])
  → busca fileChooser modal state → NO existe
  → lanza "No file chooser visible" ❌
```

### Flujo Parcheado (CORREGIDO)
```
browser_file_upload(["imagen.jpg"])
  → busca fileChooser modal state → NO existe
  → FALLBACK: page.locator('input[type="file"]').setInputFiles()
  → sube la imagen directamente al input oculto ✅
```

## Solución

El parche modifica `files.js` para añadir un **fallback** cuando no hay file chooser disponible:

1. **Método 1 (original)**: Si hay modal `fileChooser`, usa `fileChooser.setFiles()`
2. **Método 2 (fallback)**: Si no hay modal, busca `input[type="file"]` en la página y usa `locator.setInputFiles()` directamente

`setInputFiles()` de Playwright funciona a nivel de DOM/Browser API, sin pasar por el file chooser del sistema, por lo que Facebook no puede bloquearlo. Es el equivalente Playwright de `DOM.setFileInputFiles` de CDP.

## Instalación

### Automática (Windows)

```batch
scripts\apply-fix.bat
```

### Manual

1. Localiza el archivo `files.js`:
   ```
   $(npm root -g)/@playwright/mcp/node_modules/playwright/lib/mcp/browser/tools/files.js
   ```

2. Haz backup del original:
   ```bash
   copy files.js files.js.backup
   ```

3. Reemplázalo con `fix/files-patched.js`

4. Reinicia opencode (o tu cliente MCP)

### Revertir

```batch
scripts\revert-fix.bat
```

O manualmente:
```bash
copy files.js.backup files.js
```

## Verificación

1. Navega a `https://www.facebook.com/marketplace/create/item`
2. Usa `browser_file_upload` con una imagen
3. La imagen debería subirse correctamente

## Detalles Técnicos

### Código del Fallback

```javascript
// Method 2: PATCHED FALLBACK - No file chooser
const page = tab.page;
const fileInputs = page.locator('input[type="file"]');
const count = await fileInputs.count();

if (count === 0)
  throw new Error("No file chooser visible and no input[type='file'] elements found");

const firstInput = fileInputs.first();
await firstInput.setInputFiles(params.paths);
```

### ¿Por qué `setInputFiles` funciona?

- Playwright's `locator.setInputFiles()` usa el `HTMLInputElement` API del navegador (`element.files = ...`) directamente
- No depende de interacción del usuario ni de eventos de click
- Funciona incluso en inputs con `display: none` o `visibility: hidden`
- Es el equivalente Playwright de `DOM.setFileInputFiles` del Chrome DevTools Protocol

### Archivos Modificados

| Archivo | Descripción |
|---------|-------------|
| `playwright/lib/mcp/browser/tools/files.js` | Handler de `browser_file_upload` con handle parcheado |

## Notas

- **Versión probada**: @playwright/mcp v0.0.68 (Playwright v1.52.0+)
- Si actualizas `@playwright/mcp`, tendrás que reaplicar el parche
- El backup (`files.js.backup`) se crea durante la instalación automática
- Este fix modifica el paquete npm global
