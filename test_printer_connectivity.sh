#!/bin/bash

# 🧪 Script de Testing para Conectividad Impresora HTTP
# Verifica la conexión entre WebApp y Servidor Desktop

echo "🔍 TESTING IMPRESORA HTTP - CONECTIVIDAD"
echo "========================================"

# Configuración
SERVER_HOST="localhost"
SERVER_PORT="8080"
BASE_URL="http://$SERVER_HOST:$SERVER_PORT"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar resultado
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ ÉXITO${NC}: $2"
    else
        echo -e "${RED}❌ FALLO${NC}: $2"
    fi
}

# Función para mostrar advertencia
show_warning() {
    echo -e "${YELLOW}⚠️  ADVERTENCIA${NC}: $1"
}

# Función para mostrar info
show_info() {
    echo -e "${BLUE}ℹ️  INFO${NC}: $1"
}

echo "📋 Configuración:"
echo "   • Servidor: $BASE_URL"
echo "   • Timeout: 5 segundos"
echo ""

# Test 1: Verificar si el servidor está ejecutándose
echo "🔧 Test 1: Verificando servidor Desktop..."
if curl -s --connect-timeout 5 "$BASE_URL/status" > /dev/null 2>&1; then
    show_result 0 "Servidor Desktop está ejecutándose"
else
    show_result 1 "Servidor Desktop no responde"
    show_warning "Asegúrese de que la aplicación Flutter Desktop esté ejecutándose"
    echo ""
    echo "💡 Soluciones:"
    echo "   • Abrir terminal en el directorio del proyecto Desktop"
    echo "   • Ejecutar: flutter run -d windows"
    echo "   • O ejecutar el archivo .exe compilado"
    echo ""
    exit 1
fi

# Test 2: Verificar endpoint /status
echo ""
echo "🔧 Test 2: Verificando endpoint /status..."
STATUS_RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/status" 2>/dev/null)
if [ $? -eq 0 ]; then
    show_result 0 "Endpoint /status responde correctamente"
    echo "   Respuesta: $STATUS_RESPONSE"
else
    show_result 1 "Endpoint /status no responde"
fi

# Test 3: Probar configuración con nombres comunes
echo ""
echo "🔧 Test 3: Probando configuración con nombres comunes..."

COMMON_NAMES=("POS-80" "POS-80C" "Receipt Printer" "EPSON TM-T20" "Thermal Printer")

for printer_name in "${COMMON_NAMES[@]}"; do
    echo "   📝 Probando: $printer_name"
    
    CONFIG_DATA="{
        \"printerName\": \"$printer_name\",
        \"config\": {
            \"name\": \"$printer_name\",
            \"configuredAt\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\"
        }
    }"
    
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$CONFIG_DATA" \
        --connect-timeout 5 \
        "$BASE_URL/configure-printer" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        if echo "$RESPONSE" | grep -q '"status":"ok"'; then
            show_result 0 "✨ $printer_name configurado exitosamente"
            echo "      Respuesta: $RESPONSE"
            break
        elif echo "$RESPONSE" | grep -q '"status":"error"'; then
            ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//')
            show_result 1 "$printer_name - Error: $ERROR_MSG"
        else
            show_result 1 "$printer_name - Respuesta inesperada: $RESPONSE"
        fi
    else
        show_result 1 "$printer_name - No se pudo conectar al servidor"
    fi
done

# Test 4: Verificar detección específica "PosTermical"
echo ""
echo "🔧 Test 4: Probando específicamente 'PosTermical'..."

POSTERMICAL_DATA="{
    \"printerName\": \"PosTermical\",
    \"config\": {
        \"name\": \"PosTermical\",
        \"configuredAt\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\"
    }
}"

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$POSTERMICAL_DATA" \
    --connect-timeout 5 \
    "$BASE_URL/configure-printer" 2>/dev/null)

if [ $? -eq 0 ]; then
    if echo "$RESPONSE" | grep -q '"status":"ok"'; then
        show_result 0 "PosTermical configurado exitosamente"
        echo "   Respuesta: $RESPONSE"
    elif echo "$RESPONSE" | grep -q "no se puede conectar"; then
        show_result 1 "PosTermical - Error de conexión física detectado"
        echo "   Respuesta: $RESPONSE"
        echo ""
        echo "💡 Diagnóstico del problema 'PosTermical':"
        echo "   • La impresora se detecta en el sistema"
        echo "   • Pero la conexión física falla"
        echo "   • Posibles causas:"
        echo "     - Impresora apagada"
        echo "     - Cable USB defectuoso"
        echo "     - Controladores desactualizados"
        echo "     - Impresora ocupada por otro proceso"
        echo ""
        echo "🔧 Soluciones recomendadas:"
        echo "   1. Verificar que la impresora esté encendida"
        echo "   2. Reconectar cable USB"
        echo "   3. Verificar en 'Dispositivos e impresoras' de Windows"
        echo "   4. Reiniciar el servidor Desktop"
        echo "   5. Probar con nombres alternativos de la lista"
    else
        ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//')
        show_result 1 "PosTermical - Error: $ERROR_MSG"
    fi
else
    show_result 1 "PosTermical - No se pudo conectar al servidor"
fi

# Test 5: Probar impresión de prueba (si hay impresora configurada)
echo ""
echo "🔧 Test 5: Probando impresión de prueba..."

TEST_PRINT_DATA="{
    \"test\": true,
    \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\"
}"

RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$TEST_PRINT_DATA" \
    --connect-timeout 5 \
    "$BASE_URL/test-printer" 2>/dev/null)

if [ $? -eq 0 ]; then
    if echo "$RESPONSE" | grep -q '"status":"ok"'; then
        show_result 0 "Comando de impresión de prueba enviado"
        echo "   Respuesta: $RESPONSE"
        show_info "Verifique que la impresora haya impreso el ticket de prueba"
    else
        ERROR_MSG=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"//')
        show_result 1 "Impresión de prueba - Error: $ERROR_MSG"
    fi
else
    show_result 1 "No se pudo enviar comando de impresión de prueba"
fi

# Resumen final
echo ""
echo "📊 RESUMEN DE TESTING"
echo "===================="
echo "• Si todos los tests pasan: La conectividad está funcionando correctamente"
echo "• Si 'PosTermical' falla con 'no se puede conectar': Es un problema de hardware/controladores"
echo "• Usar las mejoras implementadas en la WebApp para mejor UX"
echo ""
echo "🔗 Documentación completa: PRINTER_POSTERMICAL_SOLUTION.md"
echo ""
