#!/bin/bash

# Script simple para ejecutar el servidor de prueba
# Requiere que Node.js esté instalado

echo "🚀 Iniciando servidor de prueba de impresión térmica..."

# Verificar si Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js no está instalado"
    echo "📥 Instalar desde: https://nodejs.org/"
    exit 1
fi

# Verificar si las dependencias están instaladas
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependencias..."
    npm init -y > /dev/null 2>&1
    npm install express cors > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Dependencias instaladas"
    else
        echo "❌ Error instalando dependencias"
        exit 1
    fi
fi

echo "🌐 Servidor disponible en: http://localhost:8080"
echo "🔄 Para detener: Ctrl+C"
echo ""

# Ejecutar servidor
node server_test.js
