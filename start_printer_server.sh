#!/bin/bash

# Script para instalar y ejecutar el servidor de prueba de impresión térmica

echo "🖥️  SERVIDOR HTTP DE IMPRESIÓN TÉRMICA - SETUP"
echo "=============================================="

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    echo "📥 Por favor instalar Node.js desde: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js encontrado: $(node --version)"

# Verificar si npm está disponible
if ! command -v npm &> /dev/null; then
    echo "❌ npm no está disponible"
    exit 1
fi

echo "✅ npm encontrado: $(npm --version)"

# Crear directorio temporal para el servidor
TEMP_DIR="thermal_printer_server_temp"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Copiar archivos del servidor
cp ../server_test.js ./
cp ../package-server.json ./package.json

# Instalar dependencias
echo ""
echo "📦 Instalando dependencias..."
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencias instaladas correctamente"
else
    echo "❌ Error al instalar dependencias"
    exit 1
fi

# Ejecutar servidor
echo ""
echo "🚀 Iniciando servidor de impresión..."
echo "📍 El servidor se ejecutará en: http://localhost:8080"
echo "🔄 Para detener el servidor, presiona Ctrl+C"
echo ""

# Ejecutar el servidor
node server_test.js
