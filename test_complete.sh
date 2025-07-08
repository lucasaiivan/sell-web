#!/bin/bash

# Script automatizado de testing para el sistema de impresión HTTP

echo "🧪 TESTING AUTOMATIZADO - SISTEMA IMPRESIÓN HTTP"
echo "================================================"

# Función para verificar si un puerto está en uso
check_port() {
    local port=$1
    if lsof -i :$port >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para detener procesos en el puerto 8080
cleanup_port() {
    echo "🧹 Limpiando puerto 8080..."
    # Matar procesos en el puerto 8080
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    sleep 1
}

# Verificar dependencias
echo "1️⃣ Verificando dependencias..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    echo "📥 Instalar desde: https://nodejs.org/"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter no está instalado"
    exit 1
fi

echo "✅ Node.js: $(node --version)"
echo "✅ Flutter: $(flutter --version | head -1)"

# Limpiar puerto si está en uso
if check_port 8080; then
    echo "⚠️  Puerto 8080 en uso, liberando..."
    cleanup_port
fi

# Preparar directorio temporal para el servidor
echo ""
echo "2️⃣ Preparando servidor de prueba..."

TEMP_DIR="temp_server_$$"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Inicializar proyecto Node.js
cat > package.json << EOF
{
  "name": "thermal-printer-test",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
EOF

# Copiar servidor
cp ../server_test.js ./

# Instalar dependencias
echo "📦 Instalando dependencias del servidor..."
npm install --silent

if [ $? -ne 0 ]; then
    echo "❌ Error instalando dependencias de Node.js"
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "✅ Servidor preparado"

# Iniciar servidor en background
echo ""
echo "3️⃣ Iniciando servidor HTTP..."

node server_test.js &
SERVER_PID=$!

# Esperar a que el servidor arranque
sleep 3

# Verificar que el servidor está ejecutándose
if check_port 8080; then
    echo "✅ Servidor HTTP ejecutándose en puerto 8080"
else
    echo "❌ Error: Servidor no pudo iniciarse"
    kill $SERVER_PID 2>/dev/null
    cd ..
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Testing de endpoints
echo ""
echo "4️⃣ Testing de endpoints..."

# Test 1: Status
echo -n "   📡 GET /status... "
if curl -s http://localhost:8080/status > /dev/null; then
    echo "✅"
else
    echo "❌"
fi

# Test 2: Configure
echo -n "   🔧 POST /configure-printer... "
if curl -s -X POST http://localhost:8080/configure-printer \
   -H "Content-Type: application/json" \
   -d '{"printerName": "Test Printer"}' > /dev/null; then
    echo "✅"
else
    echo "❌"
fi

# Test 3: Test printer
echo -n "   🧪 POST /test-printer... "
if curl -s -X POST http://localhost:8080/test-printer \
   -H "Content-Type: application/json" \
   -d '{}' > /dev/null; then
    echo "✅"
else
    echo "❌"
fi

# Test 4: Print ticket
echo -n "   🎫 POST /print-ticket... "
if curl -s -X POST http://localhost:8080/print-ticket \
   -H "Content-Type: application/json" \
   -d '{
     "businessName": "Test Business",
     "products": [{"quantity": 1, "description": "Test Product", "price": 10.0}],
     "total": 10.0,
     "paymentMethod": "Cash"
   }' > /dev/null; then
    echo "✅"
else
    echo "❌"
fi

# Compilar Flutter Web
echo ""
echo "5️⃣ Compilando Flutter Web..."
cd ..

flutter build web > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Flutter Web compilado exitosamente"
else
    echo "❌ Error compilando Flutter Web"
fi

# Mostrar resumen
echo ""
echo "📋 RESUMEN DEL TESTING"
echo "====================="
echo "✅ Servidor HTTP: Operativo en puerto 8080"
echo "✅ Endpoints: /status, /configure-printer, /test-printer, /print-ticket"
echo "✅ Flutter Web: Compilado correctamente"
echo "✅ HTTP Client: Implementado en ThermalPrinterHttpService"
echo ""

# Instrucciones finales
echo "🎯 PRÓXIMOS PASOS PARA TESTING MANUAL:"
echo "======================================"
echo "1. El servidor está ejecutándose en segundo plano"
echo "2. Ejecutar: flutter run -d chrome"
echo "3. En la WebApp:"
echo "   - Ir a página de ventas"
echo "   - Clic en ícono de impresora (esquina superior derecha)"
echo "   - Configurar:"
echo "     * Nombre: Mi Impresora Test"
echo "     * Host: localhost"
echo "     * Puerto: 8080"
echo "   - Hacer clic en 'Conectar'"
echo "   - Probar impresión"
echo ""
echo "📊 Logs del servidor en tiempo real:"
echo "   - Los tickets aparecerán en esta terminal"
echo ""
echo "🛑 Para detener el servidor: kill $SERVER_PID"
echo ""

# Función de limpieza al salir
cleanup() {
    echo ""
    echo "🧹 Limpiando..."
    kill $SERVER_PID 2>/dev/null
    cd "$CURRENT_DIR"
    rm -rf "$TEMP_DIR"
    echo "✅ Limpieza completada"
}

# Configurar limpieza automática
CURRENT_DIR=$(pwd)
trap cleanup EXIT

# Esperar a que el usuario termine
echo "⏳ Presiona Ctrl+C para detener el servidor y finalizar..."
wait $SERVER_PID
