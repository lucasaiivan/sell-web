# 📚 Lib - Directorio Principal de la Aplicación

Directorio raíz que contiene toda la implementación de la aplicación, organizada siguiendo **Feature-First + Clean Architecture**.

## 🎯 Filosofía de Organización

Este proyecto implementa una **arquitectura híbrida en transición**:

1. **Legacy Structure** (domain/, data/, presentation/ en raíz): Código existente compartido por múltiples features
2. **Feature-First** (features/): Nuevos módulos autónomos con Clean Architecture interna
3. **Core Infrastructure** (core/): Funcionalidades transversales y reutilizables

### Objetivo de la Migración

Migrar gradualmente de la estructura legacy hacia **Feature-First puro**, donde cada feature contiene su propio \`domain/\`, \`data/\` y \`presentation/\`.

## 📂 Estructura Actual

\`\`\`
lib/
├── 📱 main.dart                 # Punto de entrada + Setup de DI + Firebase
│
├── 🏗️ core/                     # Infraestructura transversal [VER core/README.md]
│   ├── config/                  # Configuraciones (Firebase, OAuth, App)
│   ├── constants/               # Constantes globales
│   ├── di/                      # Dependency Injection (get_it + injectable)
│   ├── errors/                  # Failures y Exceptions
│   ├── mixins/                  # Mixins reutilizables
│   ├── presentation/            # UI compartida
│   ├── services/                # Servicios de infraestructura
│   ├── usecases/                # Contrato base UseCase<Type, Params>
│   └── utils/                   # Utilidades
│
├── 💾 data/ [LEGACY]            # Implementaciones de repositorios compartidos
│   ├── auth_repository_impl.dart
│   ├── account_repository_impl.dart
│   ├── catalogue_repository_impl.dart
│   └── cash_register_repository_impl.dart
│
├── 🎯 domain/ [LEGACY]          # Entidades y contratos compartidos
│   ├── entities/                # Entidades compartidas
│   ├── repositories/            # Contratos de repositorios
│   └── usecases/                # UseCases compartidos
│
├── 🎨 presentation/ [LEGACY]    # Providers y páginas globales
│   ├── providers/               # Providers globales
│   ├── pages/                   # Páginas principales (en transición)
│   └── widgets/                 # Widgets compartidos (migrados a core/)
│
└── ✨ features/ [FEATURE-FIRST] # Módulos de negocio autónomos
    ├── 🔐 auth/                 # Autenticación [EN DESARROLLO]
    ├── 🏠 home/                 # Dashboard Principal [COMPLETO]
    ├── 🚪 landing/              # Landing Page [COMPLETO]
    ├── 📦 catalogue/            # Catálogo [EN DESARROLLO]
    ├── 💰 sales/                # POS [EN DESARROLLO]
    ├── 💵 cash_register/        # Caja [EN DESARROLLO]
    ├── 📊 analytics/            # Analytics [COMPLETO - Feature-First puro]
    └── 👥 multiuser/            # Multiusuario [PLANEADO]
\`\`\`

## 🔄 Flujo de Dependencias

### Dirección de Dependencias (Clean Architecture)

\`\`\`
Presentation Layer → Domain Layer ← Data Layer
     (UI)              (Logic)        (Implementation)
\`\`\`

**Reglas estrictas**:
- ✅ \`presentation/\` puede importar \`domain/\`
- ✅ \`data/\` puede importar \`domain/\`
- ❌ \`domain/\` NO importa \`presentation/\` ni \`data/\`
- ✅ Todos pueden importar \`core/\`
- ❌ \`core/\` NO importa features específicos

## 📋 Convenciones de Imports

### Dentro del mismo feature
\`\`\`dart
// ✅ Usar imports relativos
import '../domain/entities/product.dart';
import '../../data/models/product_model.dart';
\`\`\`

### Cross-feature o desde core
\`\`\`dart
// ✅ Usar imports absolutos
import 'package:sellweb/core/presentation/widgets/buttons/app_button.dart';
import 'package:sellweb/features/analytics/domain/entities/sales_analytics.dart';
\`\`\`

## 📖 Documentación Relacionada

- [Core README](core/README.md) - Infraestructura transversal
- [Features README](features/README.md) - Módulos de negocio
- [Domain README](domain/README.md) - Lógica de negocio legacy
- [Data README](data/README.md) - Implementaciones legacy

---

**Última actualización**: Noviembre 2025
