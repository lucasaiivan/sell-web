# 🔧 Guía de Solución de Problemas - Impresora Térmica

## ❌ Errores Comunes y Soluciones

### 1. **"Fallo al ejecutar 'transferOut' en 'USBDevice': El endpoint especificado no forma parte de una interfaz reclamada"**

**Causa**: La aplicación no pudo establecer comunicación correcta con la impresora USB.

**Soluciones**:
1. **Desconectar y reconectar** la impresora del puerto USB
2. **Cambiar a otro puerto USB** diferente
3. **Reiniciar el navegador** completamente
4. **Verificar que la impresora esté encendida** y en estado listo
5. **Probar con configuración automática** (dejar campos Vendor/Product ID vacíos)

### 2. **"NotFoundError: Impresora no encontrada"**

**Causa**: El sistema no detecta la impresora conectada.

**Soluciones**:
1. **Verificar conexión física** del cable USB
2. **Comprobar que la impresora esté encendida**
3. **Usar un cable USB diferente**
4. **Probar en otro puerto USB**
5. **Verificar en Administrador de dispositivos** (Windows) que la impresora sea detectada

### 3. **"SecurityError: Error de permisos"**

**Causa**: El navegador no tiene permisos para acceder a dispositivos USB.

**Soluciones**:
1. **Usar Chrome o Edge** (Firefox y Safari no soportan WebUSB)
2. **Actualizar la página** y volver a intentar
3. **Permitir acceso USB** cuando el navegador lo solicite
4. **Verificar configuración de seguridad** del navegador

---

## 🛠 **Pasos de Diagnóstico**

### Verificación Básica
1. ✅ **Impresora encendida** y con papel
2. ✅ **Cable USB conectado** firmemente
3. ✅ **Navegador compatible** (Chrome/Edge)
4. ✅ **Permisos USB** otorgados

### Verificación Avanzada
1. **Administrador de dispositivos** (Windows):
   - Buscar impresora en "Impresoras" o "Dispositivos USB"
   - Verificar que no tenga errores (ícono amarillo)

2. **Información del sistema** (macOS):
   - Apple > Acerca de esta Mac > Informe del sistema
   - Hardware > USB
   - Buscar la impresora en la lista

3. **Comando terminal** (Linux/macOS):
   ```bash
   lsusb
   ```

---

## 🔧 **Configuraciones Probadas**

### Impresoras Comunes
| Marca/Modelo | Vendor ID | Product ID | Notas |
|--------------|-----------|------------|-------|
| Epson TM-T20 | 04b8 | 0202 | Más estable |
| Genérica 58mm | 0525 | a4a8 | Usar detección automática |
| Star TSP143 | 0519 | 0001 | Compatible |
| Bixolon SRP-275 | 1504 | 0006 | Requiere driver |

### Configuraciones de Interfaz/Endpoint
Si la detección automática falla, probar estas combinaciones (ordenadas por probabilidad):
- **Interfaz 0, Endpoint 3** ← **MÁS COMÚN EN IMPRESORAS TÉRMICAS**
- **Interfaz 0, Endpoint 1**
- **Interfaz 0, Endpoint 2**
- **Interfaz 0, Endpoint 4**
- **Interfaz 1, Endpoint 3**
- **Interfaz 1, Endpoint 1**
- **Interfaz 1, Endpoint 2**
- **Interfaz 1, Endpoint 4**

---

## 🌐 **Limitaciones por Navegador**

### ✅ **Compatible**
- **Chrome 61+**: Soporte completo
- **Edge 79+**: Soporte completo
- **Opera 48+**: Soporte completo

### ❌ **No Compatible**
- **Firefox**: No soporta WebUSB API
- **Safari**: No soporta WebUSB API
- **Internet Explorer**: No soportado

---

## 📋 **Checklist de Troubleshooting**

### Antes de Reportar Problemas
- [ ] Impresora encendida y con papel
- [ ] Cable USB en buen estado
- [ ] Navegador Chrome o Edge actualizado
- [ ] Permisos USB otorgados
- [ ] Probado desconectar/reconectar impresora
- [ ] Probado diferentes puertos USB
- [ ] Probado reiniciar navegador
- [ ] Probado detección automática (campos vacíos)

### Información a Proporcionar
1. **Modelo exacto** de la impresora
2. **Sistema operativo** y versión
3. **Navegador** y versión
4. **Mensaje de error** completo
5. **Configuración** utilizada (Vendor/Product ID)

---

## 🚀 **Mejores Prácticas**

### Para Usuarios Finales
1. **Usar detección automática** siempre primero
2. **Mantener impresora conectada** durante toda la sesión
3. **No cambiar puertos USB** durante el uso
4. **Permitir permisos** cuando el navegador los solicite

### Para Desarrolladores
1. **Implementar retry logic** con múltiples configuraciones
2. **Proporcionar mensajes de error específicos**
3. **Incluir logging detallado** en modo debug
4. **Validar entrada de usuario** para IDs numéricos

---

## 📞 **Soporte Técnico**

Si ninguna solución funciona:
1. **Verificar modelo específico** en lista de compatibilidad
2. **Probar con otra impresora** si está disponible
3. **Contactar soporte técnico** con información completa del checklist
4. **Considerar impresora de red** como alternativa

---

*Última actualización: Julio 2025*
