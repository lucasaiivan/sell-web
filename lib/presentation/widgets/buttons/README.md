# Buttons

Este directorio contiene los componentes de botones reutilizables de la aplicación.

## Componentes

### `AppButton` (`app_button.dart`)
Componente unificado para todos los botones de la aplicación. Soporta múltiples variantes:
- `AppButton.primary`: Botón principal elevado.
- `AppButton.text`: Botón de texto.
- `AppButton.outlined`: Botón con borde.
- `AppButton.filled`: Botón con relleno.
- `AppButton.fab`: Botón flotante.

## Uso
```dart
AppButton.primary(
  text: 'Guardar',
  onPressed: () {},
)
```
