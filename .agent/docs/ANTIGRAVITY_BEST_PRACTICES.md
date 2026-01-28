# 🧠 Antigravity Workspace: Mejores Prácticas y Estratregias

Este documento recopila las mejores estrategias, trucos y patrones para estructurar un entorno de trabajo ("workspace") optimizado para el Agente Antigravity (y agentes de IA avanzados en general).

---

## 📂 La Estructura `.agent` (El Cerebro)

La carpeta `.agent` en la raíz del proyecto es el estándar de oro para documentar el conocimiento del proyecto.

### 🔬 `.agent/cortex/` (Identidad del Agente )
*Identidad del agente.*
- **Contenido:** Identidad del agente.
- **Beneficio:** El Agente es el Socio Tecnológico Senior de Iván. No eres un simple asistente; eres un co-arquitecto. Tu misión es desarrollar software robusto, escalable, priorizando Entender las necesidades del negocio y las estructuras del proyecto, y luego implementarlas de manera eficiente y segura.
- **Ejemplos:**
    - `IDENTITY.md`: (ej. Identidad del agente,etc.) 
    - `PRIME_DIRECTIVES.md`: (ej. usar el español siempre para comunicarte con el usuario y documentarte en español, Eficiencia,Claridad sobre Astucia, silosofia,etc.)
    - 'SYNAPSE_MAP.md': Mapa de la red de synapses del agente (ej.procedimientos de pensamiento, Flujo de Trabajo y pensamiento,CONSULTA DE REGLAS,GESTIÓN DE CONOCIMIENTO,etc.)


### 📜 `.agent/rules/` (Leyes Inmutables)
*Instrucciones que el agente debe seguir SIEMPRE.*
- **Contenido:** Stack tecnológico, convenciones de nombres, arquitectura (Clean Arch, MVC), guías de estilo.
- **Formato:** Archivos `.md` cortos y específicos.
- **Ejemplos:**
    - `project-context.md`: Visión general, objetivos del proyecto.
    - `tech-stack.md`: Versiones exactas (Flutter 3.x, Firebase, etc.).
    - `coding-files-standards.md`: Estructura de carpetas, archivos,style generales, etc.

### ⚡ `.agent/workflows/` (Procedimientos Estándar)
*Recetas paso a paso para tareas repetitivas.*
- **Contenido:** Scripts/skills, manuales o checklists para procesos complejos.
- **Beneficio:** Evita errores humanos y garantiza consistencia.
- **Ejemplos:**
    - `deploy-production.md`: Pasos para build y deploy.
    - `create-feature.md`: Checklist para crear un nuevo módulo (Domain -> Data -> Presentation).
    - `debug-guide.md`: Pasos comunes para solucionar errores conocidos.

### 📚 `.agent/docs/` (Base de Conocimiento)
*Documentación técnica viva sobre la infraestructura.*
- **Contenido:** Esquemas de BD, diagramas de arquitectura, explicaciones de lógica de negocio compleja.
- **Ejemplos:**
    - `ui-ux-guide.md`: (ej. Paleta de colores, tipografía, componentes,Material desing 3, patrones de diseño, etc.)
    - `database-schema.md`: Estructura de Firestore/SQL (ej. direcciones de las colecciones, etc.).
    - `api-endpoints.md`: Contratos de API (ej. endpoints, parámetros, respuestas, etc.).
    - `architecture-overview.md`: Explica la estructura del proyecto y la relación entre capas (ej. Clean Arch, MVC, etc.).
    - `business_logic.md`: (ej. Reglas: cómo se calcula el cierre de caja, como se manejan los impuestos, etc.)

---

Este documento debe vivir en tu repositorio y evolucionar con él. Un buen workspace es un jardín que se cuida constantemente.
