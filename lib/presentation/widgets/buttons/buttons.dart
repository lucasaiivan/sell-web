// Exportaciones de botones
export 'app_button.dart';
export 'app_bar_button.dart';
export 'app_text_button.dart';
export 'search_button.dart';
export 'app_floating_action_button.dart';
export 'theme_control_buttons.dart';

// Importar para alias de compatibilidad
import 'app_button.dart';

// Alias para compatibilidad con PrimaryButton (deprecated - usar AppButton.primary())
@Deprecated('Usar AppButton.primary() en su lugar')
typedef PrimaryButton = AppButton;
