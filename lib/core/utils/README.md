## Descripción
Utilidades y helpers que proporcionan funciones comunes y herramientas de apoyo para toda la aplicación.

## Contenido
```
utils/
├── utils.dart - Archivo de barril que exporta todas las utilidades
├── formatters/ - Formateadores de datos
└── helpers/ - Funciones helper específicas
```
utils/
├── formatters/                    # 💱 Formateo de datos
│   ├── currency_formatter.dart    # Formateo de moneda y precios
│   ├── date_formatter.dart        # Formateo de fechas y tiempos
│   ├── text_formatter.dart        # Formateo y manipulación de texto
│   ├── money_input_formatter.dart # Formateadores para inputs de dinero
│   └── formatters.dart           # Exportaciones centralizadas
├── helpers/                       # 🛠️ Helpers especializados
│   ├── responsive_helper.dart     # Utilidades responsive
│   ├── uid_helper.dart           # Generación de IDs únicos (migrado)
│   └── helpers.dart              # Exportaciones centralizadas
├── utils.dart                    # 📦 Exportaciones principales 
```
