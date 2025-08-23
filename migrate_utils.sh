#!/bin/bash

# Script para migrar automáticamente de Publications/Utils a las nuevas utilidades

echo "🔄 Iniciando migración automática de utilidades..."

# Directorio de trabajo
WORK_DIR="/Users/lucasaiivan/StudioProjects/sell-web"

# Función para reemplazar en archivo
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [[ -f "$file" ]]; then
        # Usar sed en macOS
        sed -i '' "s/${search}/${replace}/g" "$file"
        echo "✅ Reemplazado en: $(basename "$file")"
    fi
}

# Cambiar al directorio de trabajo
cd "$WORK_DIR"

echo "📁 Procesando archivos..."

# Buscar y reemplazar Publications.getFormatoPrecio
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getFormatoPrecio" {} \;); do
    replace_in_file "$file" "Publications\.getFormatoPrecio" "CurrencyFormatter.formatPrice"
done

# Buscar y reemplazar Publications.getFormatAmount
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getFormatAmount" {} \;); do
    replace_in_file "$file" "Publications\.getFormatAmount" "CurrencyFormatter.formatAmount"
done

# Buscar y reemplazar Publications.generateUid
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.generateUid" {} \;); do
    replace_in_file "$file" "Publications\.generateUid" "UidGenerator.generateUid"
done

# Buscar y reemplazar Publications.getFechaPublicacionFormating
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getFechaPublicacionFormating" {} \;); do
    replace_in_file "$file" "Publications\.getFechaPublicacionFormating" "DateFormatter.formatPublicationDate"
done

# Buscar y reemplazar Publications.getTiempoTranscurrido
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getTiempoTranscurrido" {} \;); do
    replace_in_file "$file" "Publications\.getTiempoTranscurrido" "DateFormatter.getElapsedTime"
done

# Buscar y reemplazar Publications.getFechaPublicacion
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getFechaPublicacion" {} \;); do
    replace_in_file "$file" "Publications\.getFechaPublicacion" "DateFormatter.getDetailedPublicationDate"
done

# Buscar y reemplazar Publications.getFechaPublicacionSimple
for file in $(find lib -name "*.dart" -exec grep -l "Publications\.getFechaPublicacionSimple" {} \;); do
    replace_in_file "$file" "Publications\.getFechaPublicacionSimple" "DateFormatter.getSimplePublicationDate"
done

# Buscar y reemplazar Utils().getTimestampNow()
for file in $(find lib -name "*.dart" -exec grep -l "Utils()\.getTimestampNow()" {} \;); do
    replace_in_file "$file" "Utils()\.getTimestampNow()" "DateFormatter.getCurrentTimestamp()"
done

# Buscar y reemplazar Utils.getRandomColor()
for file in $(find lib -name "*.dart" -exec grep -l "Utils\.getRandomColor()" {} \;); do
    replace_in_file "$file" "Utils\.getRandomColor()" "ColorHelper.getRandomColor()"
done

# Buscar y reemplazar Utils.normalizeText
for file in $(find lib -name "*.dart" -exec grep -l "Utils\.normalizeText" {} \;); do
    replace_in_file "$file" "Utils\.normalizeText" "TextFormatter.normalizeText"
done

echo "🎯 Actualizando imports..."

# Actualizar imports en archivos que usan las nuevas utilidades
for file in $(find lib -name "*.dart" -exec grep -l "CurrencyFormatter\|DateFormatter\|UidGenerator\|ColorHelper\|TextFormatter" {} \;); do
    # Verificar si ya tiene el import
    if ! grep -q "import.*core\.dart" "$file" && ! grep -q "import.*core/core\.dart" "$file"; then
        # Buscar otros imports de core para determinar el path relativo correcto
        if grep -q "import.*\.\./\.\./core/" "$file"; then
            # Path relativo desde subdirectorios
            sed -i '' '1i\
import '\''../../core/core.dart'\'';
' "$file"
        elif grep -q "import.*\.\./core/" "$file"; then
            # Path relativo desde directorio padre
            sed -i '' '1i\
import '\''../core/core.dart'\'';
' "$file"
        else
            # Path absoluto o relativo simple
            sed -i '' '1i\
import '\''package:sellweb/core/core.dart'\'';
' "$file"
        fi
        echo "📦 Import añadido a: $(basename "$file")"
    fi
done

echo "🧹 Limpiando imports obsoletos..."

# Remover imports obsoletos de fuctions.dart
for file in $(find lib -name "*.dart" -exec grep -l "core/utils/fuctions\.dart" {} \;); do
    sed -i '' '/core\/utils\/fuctions\.dart/d' "$file"
    echo "🗑️  Import obsoleto removido de: $(basename "$file")"
done

echo "✨ Migración completada!"
echo "📋 Resumen:"
echo "   - Publications.* → Nuevas utilidades especializadas"
echo "   - Utils.* → Nuevas utilidades especializadas"
echo "   - Imports actualizados automáticamente"
echo ""
echo "⚠️  Verificar manualmente:"
echo "   - Compilación del proyecto"
echo "   - Funcionalidad de formateo de precios"
echo "   - Generación de IDs únicos"
