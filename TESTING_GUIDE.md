# 🧪 Guía de Testing - Servidor HTTP de Impresión

## 🚀 Inicio Rápido

### 1. Iniciar el Servidor HTTP de Prueba

```bash
# En el directorio del proyecto
./run_server.sh
```

Si funciona correctamente, verás:
```
🖥️  SERVIDOR HTTP DE IMPRESIÓN TÉRMICA
=====================================
🌐 Servidor ejecutándose en: http://localhost:8080
🔗 Acceso desde red local: http://0.0.0.0:8080
📋 Endpoints disponibles:
   GET  /status           - Estado del servidor
   POST /configure-printer - Configurar impresora
   POST /test-printer     - Prueba de impresión
   POST /print-ticket     - Imprimir ticket
=====================================
✅ Listo para recibir comandos de impresión
```

### 2. Ejecutar la WebApp

```bash
# En otra terminal
flutter run -d chrome
```

### 3. Testing de la Integración

1. **Abrir la aplicación web**
2. **Ir a la página de ventas**
3. **Hacer clic en el ícono de impresora** (esquina superior derecha)
4. **En el diálogo de configuración:**
   - Nombre de impresora: `Mi Impresora Test`
   - Host del servidor: `localhost` (por defecto)
   - Puerto: `8080` (por defecto)
   - Hacer clic en **"Conectar"**

### 4. Resultados Esperados

#### ✅ Si el servidor está ejecutándose:
- La aplicación mostrará: "✅ Servidor conectado"
- En el terminal del servidor verás logs de conexión
- El botón **"Probar Impresión"** funcionará

#### ❌ Si el servidor NO está ejecutándose:
- La aplicación mostrará: "❌ Error de conexión: Connection refused"
- El diálogo indicará que no hay conexión

## 🧪 Test Manual de Endpoints

### Verificar estado del servidor:
```bash
curl http://localhost:8080/status
```

Respuesta esperada:
```json
{
  "status": "ok",
  "message": "Servidor de impresión activo",
  "timestamp": "2025-01-07T...",
  "printer": "No configurada"
}
```

### Configurar impresora:
```bash
curl -X POST http://localhost:8080/configure-printer \
  -H "Content-Type: application/json" \
  -d '{"printerName": "Test Printer"}'
```

### Imprimir ticket de prueba:
```bash
curl -X POST http://localhost:8080/test-printer \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Imprimir ticket completo:
```bash
curl -X POST http://localhost:8080/print-ticket \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Mi Negocio Test",
    "products": [
      {"quantity": 2, "description": "Producto A", "price": 10.50},
      {"quantity": 1, "description": "Producto B", "price": 5.25}
    ],
    "total": 26.25,
    "paymentMethod": "Efectivo",
    "customerName": "Cliente Test"
  }'
```

## 🔍 Depuración

### Logs del Servidor
- Todos los requests se muestran en tiempo real en el terminal
- Los tickets se "imprimen" en la consola para verificar contenido

### Logs de la WebApp
- Abrir DevTools del navegador (F12)
- Ir a la pestaña **Console**
- Los logs mostrarán las requests HTTP y respuestas

### Problemas Comunes

1. **"Connection refused"**
   - ✅ Verificar que el servidor esté ejecutándose
   - ✅ Verificar que el puerto 8080 esté libre

2. **"Timeout"**
   - ✅ Revisar firewall del sistema
   - ✅ Verificar URL y puerto en la configuración

3. **CORS errors**
   - ✅ El servidor ya incluye configuración CORS
   - ✅ Verificar headers en DevTools

## 📱 Testing desde Dispositivos Móviles

Para probar desde un teléfono en la misma red:

1. **Obtener IP de la computadora:**
   ```bash
   # En macOS/Linux
   ifconfig | grep inet
   
   # En Windows
   ipconfig
   ```

2. **Iniciar servidor en todas las interfaces:**
   ```bash
   # Editar server_test.js, línea del listen:
   app.listen(port, '0.0.0.0', () => {
   ```

3. **Configurar en la WebApp:**
   - Host del servidor: `192.168.x.x` (IP de tu computadora)
   - Puerto: `8080`

## 🎯 Casos de Prueba

### ✅ Casos Exitosos
- [ ] Conectar con servidor local
- [ ] Configurar impresora correctamente
- [ ] Imprimir ticket de prueba
- [ ] Imprimir ticket de venta real
- [ ] Reconectar después de desconexión

### ❌ Casos de Error
- [ ] Servidor no disponible
- [ ] Puerto incorrecto
- [ ] Timeout de conexión
- [ ] Datos de ticket inválidos

---

**Próximo paso:** Una vez confirmado que funciona el servidor de prueba, implementar el servidor real con impresión física en Flutter Desktop.
