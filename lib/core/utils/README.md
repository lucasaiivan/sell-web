# 🔧 Utils - Utilidades y Helpers

El directorio `utils` contiene **utilidades reutilizables** que proporcionan funcionalidades comunes y transformaciones de datos utilizadas en toda la aplicación.

## 🎯 Propósito

Ofrecer funciones puras, helpers y utilidades que:
- **No dependan del contexto de Flutter** (excepto helpers específicos de UI)
- **Sean altamente reutilizables** entre diferentes features
- **Faciliten transformaciones** de datos comunes
- **Mantengan lógica compleja** en un lugar centralizado

## 📁 Nueva Estructura Reorganizada

```
utils/
├── formatters/                    # 💱 Formateo de datos
│   ├── currency_formatter.dart    # Formateo de moneda y precios
│   ├── date_formatter.dart        # Formateo de fechas y tiempos
│   ├── text_formatter.dart        # Formateo y manipulación de texto
│   ├── money_input_formatter.dart # Formateadores para inputs de dinero
│   └── formatters.dart           # Exportaciones centralizadas
├── helpers/                       # 🛠️ Helpers especializados
│   ├── responsive_helper.dart     # Utilidades responsive (existente)
│   └── helpers.dart              # Exportaciones centralizadas
├── generators/                    # 🆔 Generadores
│   ├── uid_generator.dart         # Generación de IDs únicos
│   └── generators.dart           # Exportaciones centralizadas
├── utils.dart                    # 📦 Exportaciones principales
└── fuctions.dart                 # ⚠️ ARCHIVO ORIGINAL (a eliminar)
```
