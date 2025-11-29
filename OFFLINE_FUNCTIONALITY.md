# Funcionalidad Offline - Sell Web

## 🚀 Implementación Completa

La aplicación ahora funciona **completamente sin internet** y sincroniza automáticamente con la nube al reconectarse.

---

## 📦 ¿Qué se implementó?

### 1. **Persistencia Offline de Firestore** (`lib/main.dart`)
```dart
await FirebaseFirestore.instance.enablePersistence(
  const PersistenceSettings(synchronizeTabs: true),
);
```

- **Catálogo de productos**: Se guarda localmente en IndexedDB (Web) o SQLite (Móvil).
- **Clientes y datos**: Disponibles después de la primera carga.
- **Sincronización automática**: Al reconectar, todas las operaciones pendientes se envían a Firestore.

### 2. **Indicador Visual de Conectividad**
- **`ConnectivityProvider`**: Monitorea el estado de conexión en tiempo real.
- **`ConnectivityIndicator`**: Widget que muestra "Sin conexión" en el AppBar cuando estás offline.
- Se muestra en:
  - Página de Ventas (`SalesPage`)
  - Página de Catálogo (`CataloguePage`)

---

## 🎯 Cómo Funciona

### **Online (Con Internet)**
1. Las ventas se guardan directamente en Firestore.
2. El catálogo se carga desde la nube y se guarda en caché local.
3. Las imágenes se descargan y guardan en caché.

### **Offline (Sin Internet)**
1. **Ventas**: Se guardan en una cola local y se sincronizan al reconectar.
2. **Catálogo**: Se lee desde la caché local (última versión descargada).
3. **Configuración**: Siempre disponible (guardada en `SharedPreferences`).
4. **Indicador**: Aparece un chip naranja con "Sin conexión" en el AppBar.

### **Reconexión (Vuelve Internet)**
1. Firestore detecta automáticamente la conexión.
2. Envía todas las ventas pendientes a la nube (en orden FIFO).
3. El indicador "Sin conexión" desaparece.
4. Los nuevos datos se descargan y actualizan la caché.

---

## 📊 Datos Disponibles Offline

| Tipo de Dato | Disponibilidad Offline | Notas |
|--------------|------------------------|-------|
| **Ticket Actual** | ✅ 100% | Se guarda en `SharedPreferences` |
| **Último Ticket** | ✅ 100% | Disponible para reimpresión |
| **Configuración** | ✅ 100% | Tema, cuenta, caja, impresora |
| **Catálogo** | ✅ Después de 1ra sesión | Última versión cargada |
| **Clientes** | ✅ Si se consultaron antes | En caché de Firestore |
| **Imágenes** | ⚠️ Parcial | Solo las vistas recientemente |

---

## 🧪 Cómo Probar

### **Simulación de Modo Offline**

1. **En Chrome DevTools**:
   - Abre DevTools (F12)
   - Ve a la pestaña "Network"
   - Selecciona "Offline" en el dropdown
   - La app seguirá funcionando con datos locales

2. **Verificar persistencia**:
   ```bash
   # Abrir la app
   flutter run -d chrome
   
   # Agregar productos al carrito
   # Activar modo offline en DevTools
   # Los productos siguen disponibles
   # Hacer una venta → Se guarda localmente
   # Desactivar modo offline → La venta se sincroniza
   ```

3. **Ver logs de sincronización**:
   - En la consola verás:
     - `✅ Persistencia offline habilitada correctamente`
     - `🌐 Estado de conexión: OFFLINE`
     - `🌐 Estado de conexión: ONLINE`

---

## ⚠️ Limitaciones

1. **Carga Inicial**: La app debe abrirse con internet **al menos una vez** para descargar el catálogo.
2. **Modo Incógnito**: No funciona persistencia en modo privado del navegador.
3. **Almacenamiento**: El navegador puede borrar la caché si se queda sin espacio (poco común).
4. **Imágenes Grandes**: Las imágenes no se guardan en la caché de Firestore, solo en `cached_network_image`.

---

## 🔧 Arquitectura

### **Archivos Modificados/Creados**

```
lib/
├── main.dart                                    [MODIFICADO]
│   └── Habilitada persistencia de Firestore
│
├── core/presentation/
│   ├── providers/
│   │   └── connectivity_provider.dart           [NUEVO]
│   │       └── Monitorea estado de conexión
│   └── widgets/
│       └── connectivity_indicator.dart          [NUEVO]
│           └── Indicador visual "Sin conexión"
│
└── features/
    ├── sales/presentation/pages/
    │   └── sales_page.dart                      [MODIFICADO]
    │       └── Agregado ConnectivityIndicator
    └── catalogue/presentation/pages/
        └── catalogue_page.dart                  [MODIFICADO]
            └── Agregado ConnectivityIndicator
```

### **Flujo de Datos**

```
Usuario sin Internet
    ↓
[ConnectivityProvider detecta offline]
    ↓
[ConnectivityIndicator muestra "Sin conexión"]
    ↓
[Usuario realiza venta]
    ↓
[Firestore encola operación localmente]
    ↓
[AppDataPersistenceService guarda ticket]
    ↓
[Usuario reconecta a Internet]
    ↓
[Firestore sincroniza automáticamente]
    ↓
[ConnectivityIndicator desaparece]
```

---

## 🎉 Beneficios

1. **Resistencia a fallos**: Si se corta internet durante una venta, no se pierde nada.
2. **Velocidad**: Las operaciones son instantáneas (no esperan red).
3. **UX mejorada**: El usuario sabe cuándo está offline.
4. **Cero configuración**: Todo funciona automáticamente.

---

## 📝 Notas Técnicas

### **Persistencia en Web vs Móvil**

| Plataforma | Tecnología de Caché | Tamaño Límite |
|------------|---------------------|---------------|
| Web | IndexedDB | ~50MB (varía por navegador) |
| Android | SQLite | ~100MB (configurable) |
| iOS | SQLite | ~100MB (configurable) |

### **Sincronización de Múltiples Pestañas (Web)**

Con `synchronizeTabs: true`:
- Si abres la app en 2 pestañas, ambas comparten la misma caché.
- Los cambios se sincronizan entre pestañas.
- No hay conflictos de escritura.

---

## 🚨 Troubleshooting

### **"Persistencia no se pudo habilitar"**
- **Causa**: Modo incógnito o permisos de almacenamiento denegados.
- **Solución**: Usar el navegador en modo normal.

### **"Los datos no se sincronizan"**
- **Causa**: El navegador borró la caché por falta de espacio.
- **Solución**: Liberar espacio en el dispositivo.

### **"El indicador siempre muestra offline"**
- **Causa**: Reglas de Firestore bloquean acceso a `_connectivity_monitor`.
- **Solución**: No es necesario crear el documento, solo monitorearlo.

---

## ✅ Checklist de Verificación

- [x] Persistencia habilitada en `main.dart`
- [x] `ConnectivityProvider` registrado en providers
- [x] `ConnectivityIndicator` agregado en `SalesPage`
- [x] `ConnectivityIndicator` agregado en `CataloguePage`
- [x] Logs de depuración funcionando
- [x] Documentación completa

---

**Última actualización**: 29 de noviembre de 2025
