#!/bin/bash

# Script de prueba para verificar la corrección de persistencia de productos

echo "🧪 SCRIPT DE PRUEBA: Persistencia de Productos Seleccionados"
echo "============================================================="
echo ""

echo "📝 Pasos para probar la corrección:"
echo ""
echo "1. PERSISTENCIA BÁSICA:"
echo "   - Abre la aplicación"
echo "   - Agrega algunos productos al ticket"
echo "   - Recarga la página (F5 o Cmd+R)"
echo "   - Verifica que los productos persisten"
echo ""

echo "2. RESELECCIÓN DE CUENTA:"
echo "   - Agrega productos al ticket"
echo "   - Haz clic en el avatar/nombre de la cuenta"
echo "   - Selecciona la MISMA cuenta actual"
echo "   - Verifica que los productos persisten"
echo ""

echo "3. CAMBIO DE CUENTA:"
echo "   - Agrega productos al ticket"
echo "   - Cambia a una cuenta diferente"
echo "   - Verifica que el ticket se limpia (comportamiento esperado)"
echo ""

echo "4. VERIFICACIÓN DE LOGS:"
echo "   - Abre DevTools Console (F12)"
echo "   - Busca logs que empiecen con:"
echo "     📦 SellProvider: Ticket cargado..."
echo "     💾 SellProvider: Ticket guardado..."
echo "     ✅ SellProvider: Reseleccionando la misma cuenta..."
echo "     🔄 SellProvider: Cambiando de cuenta..."
echo ""

echo "🎯 RESULTADO ESPERADO:"
echo "   - Los productos deben persistir al recargar la página"
echo "   - Los productos deben persistir al reseleccionar la misma cuenta"
echo "   - Los productos deben limpiarse al cambiar a cuenta diferente"
echo ""

echo "Para ejecutar la aplicación: flutter run -d chrome --web-port 8080"
