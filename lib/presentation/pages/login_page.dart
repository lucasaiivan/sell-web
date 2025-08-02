import 'dart:async';
import 'dart:html' as html;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import 'package:sellweb/core/widgets/feedback/auth_feedback_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  final AuthProvider authProvider;
  const LoginPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    html.document.title = 'Punto de venta';
    final double width = MediaQuery.of(context).size.width;

    Widget content;
    if (width < 600) {
      // Móvil: apilar verticalmente
      content = Column(
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _LoginForm(authProvider: authProvider),
          ),
        ],
      );
    } else if (width < 1024) {
      // Tablet: proporción 2/3 y 1/3
      content = Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Expanded(
            flex: 1,
            child: _LoginForm(authProvider: authProvider),
          ),
        ],
      );
    } else {
      // Desktop: proporción 3/4 y 1/4
      content = Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: OnboardingIntroductionApp(),
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _LoginForm(authProvider: authProvider),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          content,
          // Botones de configuración del tema
          Positioned(
            top: 20,
            right: 20,
            child: ThemeControlButtons(
              spacing: 8,
              iconSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget : que muestra el formulario de login y controla el estado del checkbox
class _LoginForm extends StatefulWidget {
  final AuthProvider authProvider;
  const _LoginForm({required this.authProvider});
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _acceptPolicy = false;

  @override
  void initState() {
    super.initState();
    // Limpiar errores previos al inicializar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.authProvider.clearAuthError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Estilos responsivos para el texto
    final double baseFontSize = getResponsiveValue(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 13.0,
    );
  

    TextStyle aceptPolitikTextStyle = textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
          fontSize: baseFontSize * 0.95,
          height: 1.4,
        ) ??
        TextStyle(
          color: colorScheme.onSurface,
          fontSize: baseFontSize * 0.9,
          height: 1.4,
        );

    RichText text = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: aceptPolitikTextStyle,
        children: <TextSpan>[
          const TextSpan(
              text:
                  'Al iniciar en INICIAR SESIÓN, usted ha leído y acepta nuestros '),
          TextSpan(
              text: 'Términos y condiciones de uso',
              style: aceptPolitikTextStyle.copyWith(
                  decoration: TextDecoration.none, color: colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri url = Uri.parse(
                      'https://sites.google.com/view/sell-app/t%C3%A9rminos-y-condiciones-de-uso');
                  if (!await launchUrl(url)) throw 'Could not launch $url';
                }),
          const TextSpan(text: ' así también como la '),
          TextSpan(
              text: 'Política de privacidad',
              style: aceptPolitikTextStyle.copyWith(
                  decoration: TextDecoration.none, color: colorScheme.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri url = Uri.parse(
                      'https://sites.google.com/view/sell-app/pol%C3%ADticas-de-privacidad');
                  if (!await launchUrl(url)) throw 'Could not launch $url';
                }),
        ],
      ),
    );

    return Center(
      child: AnimatedBuilder(
        animation: widget.authProvider,
        builder: (context, _) {
          if (widget.authProvider.user == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Widget de feedback unificado para errores y estados
                AuthFeedbackWidget(
                  error: widget.authProvider.authError,
                  onDismissError: widget.authProvider.clearAuthError,
                ),
            
                // Texto de bienvenida centrado
                Padding(
                  padding: getResponsivePadding(
                    context,
                    mobile: const EdgeInsets.only(bottom: 50,top: 25),
                    tablet: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
                    desktop: const EdgeInsets.symmetric(horizontal: 16, vertical: 50),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ingresá a tu cuenta',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('Seguí ganando tiempo y dinero',style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.7),fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            
                // CheckboxListTile responsivo : aceptar términos y condiciones
                Container(
                  margin: getResponsivePadding(
                    context,
                    mobile: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    tablet: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    desktop: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _acceptPolicy
                          ? colorScheme.primary.withValues(alpha: 0.3)
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _acceptPolicy
                        ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                        : colorScheme.surface,
                  ),
                  child: CheckboxListTile(
                    dense: isMobile(context),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    selectedTileColor: Colors.transparent,
                    tileColor: Colors.transparent,
                    checkColor: colorScheme.onPrimary,
                    activeColor: colorScheme.primary,
                    title: text,
                    value: _acceptPolicy,
                    onChanged: (value) {
                      setState(() {
                        _acceptPolicy = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: getResponsivePadding(
                      context,
                      mobile: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      tablet: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      desktop: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
            
                // ElevatedButton : Iniciar sesión con Google
                AppButton(
                  
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  backgroundColor: Colors.blue.shade700,
                  text: "CONTINUAR CON GOOGLE",
                  icon: const Icon(Icons.login_rounded, size: 20),
                  isLoading: widget.authProvider.isSigningInWithGoogle,
                  onPressed: (_acceptPolicy &&
                          !widget.authProvider.isSigningInWithGoogle &&
                          !widget.authProvider.isSigningInAsGuest)
                      ? () async {
                          await widget.authProvider.signInWithGoogle();
                        }
                      : null,
                ), 
            
                // ElevatedButton : Iniciar como invitado
                AppButton(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 20),
                  backgroundColor: Colors.blueGrey,
                  text: "CONTINUAR COMO INVITADO",
                  isLoading: widget.authProvider.isSigningInAsGuest,
                  onPressed: (!widget.authProvider.isSigningInWithGoogle &&
                          !widget.authProvider.isSigningInAsGuest)
                      ? () async {
                          await widget.authProvider.signInAsGuest();
                        }
                      : null,
                ),
              ],
            );
          }
          // Mostrar indicador de carga mientras se procesa la autenticación exitosa
          return AuthFeedbackWidget(
            showLoading: true,
            loadingMessage: 'Configurando tu cuenta...',
          );
        },
      ),
    );
  }
}

class OnboardingIntroductionApp extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  OnboardingIntroductionApp(
      {this.colorAccent = Colors.deepPurple,
      this.colorText = Colors.white,
      super.key});

  late final Color colorAccent;
  late final Color colorText;

  @override
  State<OnboardingIntroductionApp> createState() =>
      _OnboardingIntroductionAppState();
}

class _OnboardingIntroductionAppState extends State<OnboardingIntroductionApp> {
  // source
  String sellImagen = "assets/sell02.jpeg";
  String transactionImage = "assets/sell05.jpeg";
  String catalogueImage = "assets/catalogue02.png";

  // variables para el estilo de la pantalla
  late bool darkMode;
  late Size screenSize;

// variables para el manejo de los indicadores de progreso
  double indicatorProgressItem01 = 0.0;
  double indicatorProgressItem02 = 0.0;
  double indicatorProgressItem03 = 0.0;
  late Timer timer;
  int index = 0;
  late List<Widget> widgets;

  // fuction  : maneja el evento de toque IZQUIERDO que cambian los valores de los indicadores de progreso y cambia la vista del item
  void leftTouch() {
    //  primer item : si el primer item esta en 0.0 y el segundo y tercer item estan en 0.0 entonces el primer item pasa a 1.0
    if (indicatorProgressItem01 >= 0.0 &&
        indicatorProgressItem02 == 0.0 &&
        indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 0; // siguiente vista
    }
    // segundo item : si el primer item esta en 1.0 y el segundo item esta en 0.0 y el tercer item esta en 0.0 entonces el segundo item pasa a 1.0
    else if (indicatorProgressItem01 == 1.0 &&
        indicatorProgressItem02 >= 0.0 &&
        indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 1; //  siguiente vista
    }
    //  tercer item : si el primer item esta en 1.0 y el segundo item esta en 1.0 y el tercer item esta en 0.0 entonces el tercer item pasa a 1.0
    else if (indicatorProgressItem01 == 1.0 &&
        indicatorProgressItem02 == 1.0 &&
        indicatorProgressItem03 >= 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 2; //  siguiente vista
    }
    // vuelve a la vista al princio
    else {
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 0;
    }
  }

  // fuction  : maneja el evento de toque DERECHO que cambian los valores de los indicadores de progreso
  void rightTouch() {
    // primer item : si el primer item esta en 0.0 y el segundo y tercer item estan en 0.0 entonces el primer item pasa a 1.0
    if (indicatorProgressItem01 <= 1.00 &&
        indicatorProgressItem02 == 0.0 &&
        indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 1; // siguiente vista
    }
    // segundo item : si el primer item esta en 1.0 y el segundo item esta en 0.0 y el tercer item esta en 0.0 entonces el segundo item pasa a 1.0
    else if (indicatorProgressItem02 <= 1.00 &&
        indicatorProgressItem01 > 0.0 &&
        indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 1.0;
      indicatorProgressItem03 = 0.0;
      index = 2; // siguiente vista
    }
    // tercer item  : si el primer item esta en 1.0 y el segundo item esta en 1.0 y el tercer item esta en 0.0 entonces el tercer item pasa a 1.0
    else if (indicatorProgressItem03 <= 1.00 &&
        indicatorProgressItem01 > 0.0 &&
        indicatorProgressItem02 > 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 1.0;
      indicatorProgressItem03 = 1.0;
      index = 3; // siguiente vista
    } // vuelve a la vista al principio
    else {
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 0;
    }
  }

  void positionIndicatorLogic() {
    // logica de los indicadores de posicion que cambiar cada sierto tiempo
    timer = Timer.periodic(const Duration(microseconds: 50000), (timer) {
      try {
        setState(() {
          if (indicatorProgressItem01 < 1) {
            if (indicatorProgressItem01 >= 0.1 &&
                indicatorProgressItem01 <= 0.8) {
              indicatorProgressItem01 += 0.02;
            } else {
              indicatorProgressItem01 += 0.01;
            }
            index = 0;
          }
          if (indicatorProgressItem02 < 1 && indicatorProgressItem01 >= 1) {
            if (indicatorProgressItem02 >= 0.1 &&
                indicatorProgressItem02 <= 0.8) {
              indicatorProgressItem02 += 0.02;
            } else {
              indicatorProgressItem02 += 0.01;
            }
            index = 1;
          }
          if (indicatorProgressItem03 < 1 && indicatorProgressItem02 >= 1) {
            if (indicatorProgressItem03 >= 0.1 &&
                indicatorProgressItem03 <= 0.8) {
              indicatorProgressItem03 += 0.02;
            } else {
              indicatorProgressItem03 += 0.01;
            }
            index = 2;
          }
          if (indicatorProgressItem01 >= 1 &&
              indicatorProgressItem02 >= 1 &&
              indicatorProgressItem03 >= 1) {
            indicatorProgressItem01 = 0.0;
            indicatorProgressItem02 = 0.0;
            indicatorProgressItem03 = 0.0;
          }
        });
        // ignore: empty_catches
      } catch (e) {}
    });
  }

  @override
  void initState() {
    // logicas de los indicadores de posicion
    positionIndicatorLogic();

    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos los valores
    darkMode = Theme.of(context).brightness == Brightness.dark;
    screenSize = MediaQuery.of(context).size;

    // lista de widgets con las vistas
    widgets = [
      pageView(
          context: context,
          colorContent: Colors.transparent,
          textColor: Colors.white,
          colorIcon: Colors.orange.shade300,
          iconData: Icons.monetization_on,
          titulo: "VENTAS",
          subtitulo: "Registra tus ventas de una forma simple 😊"),
      pageView(
          context: context,
          colorContent: Colors.transparent,
          textColor: Colors.white,
          colorIcon: Colors.teal.shade300,
          iconData: Icons.analytics_outlined,
          titulo: "TRANSACCIONES",
          subtitulo: "Observa las transacciones que has realizado 💰"),
      pageView(
          context: context,
          colorContent: Colors.transparent,
          textColor: Colors.white,
          colorIcon: Colors.deepPurple.shade300,
          iconData: Icons.category,
          titulo: "CATÁLOGO",
          subtitulo:
              "Arma tu catálogo y controla el stock de tus productos \n 🍫🍬🥫🍾"),
    ];

    String uriImage = index == 0
        ? sellImagen
        : index == 1
            ? transactionImage
            : catalogueImage;

    return Stack(
      children: [
        // Imagen background
        ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Opacity(
                opacity: 0.8,
                child: Image(
                    image: AssetImage(uriImage),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover))),
        // view : contenidos
        Column(
          children: [
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    //  indicador de las vistas
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            color: Colors.white,
                            backgroundColor:
                                darkMode ? Colors.white12 : Colors.black12,
                            value: indicatorProgressItem01,
                          ),
                        ),
                      ),
                    ),
                    //  indicador de vista
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            color: Colors.white,
                            backgroundColor:
                                darkMode ? Colors.white12 : Colors.black12,
                            value: indicatorProgressItem02,
                          ),
                        ),
                      ),
                    ),
                    //  indicador de vista
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(1.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            color: Colors.white,
                            backgroundColor:
                                darkMode ? Colors.white12 : Colors.black12,
                            value: indicatorProgressItem03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(child: widgets[index]),
          ],
        ),
        // controlamos los toques del usuario
        Row(
          children: [
            // toque izquierdo
            Flexible(
                child: InkWell(
              onTap: leftTouch,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
            )),
            //  toque derecho
            Flexible(
                child: InkWell(
              onTap: rightTouch,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
            )),
            //  touch
          ],
        ),
      ],
    );
  }

  Widget pageView(
      {required BuildContext context,
      Color? colorContent,
      Color textColor = Colors.black,
      AssetImage? assetImage,
      IconData? iconData,
      Color? colorIcon,
      String titulo = "",
      String subtitulo = ""}) {
    // Definimos los estilos
    colorContent ??= Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    colorIcon ??= colorContent;
    
    // Tamaños de fuente responsivos
    final double tituloFontSize = getResponsiveValue(
      context,
      mobile: 32.0,
      tablet: 42.0,
      desktop: 50.0,
    );
    
    final double subtituloFontSize = getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
    );
    
    // Tamaño del icono responsivo
    final double iconSize = getResponsiveValue(
      context,
      mobile: screenSize.height * 0.05,
      tablet: screenSize.height * 0.06,
      desktop: screenSize.height * 0.07,
    );
    
    // Padding responsivo para el icono
    final EdgeInsets iconPadding = getResponsivePadding(
      context,
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(20.0),
    );
    
    // Margin responsivo para el icono
    final EdgeInsets iconMargin = getResponsivePadding(
      context,
      mobile: const EdgeInsets.all(12.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(20.0),
    );
    
    // Espaciado responsivo
    final double topSpacing = getResponsiveValue(
      context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
    );
    
    final double bottomSpacing = getResponsiveValue(
      context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
    );

    final estiloTitulo = TextStyle(
        fontSize: tituloFontSize, 
        fontWeight: FontWeight.bold, 
        color: textColor);
    final estiloSubTitulo = TextStyle(
        fontSize: subtituloFontSize,
        fontWeight: FontWeight.bold,
        color: textColor.withValues(alpha: 0.8));

    return SafeArea(
        child: Padding(
      padding: getResponsivePadding(
        context,
        mobile: const EdgeInsets.all(12.0),
        tablet: const EdgeInsets.all(16.0),
        desktop: const EdgeInsets.all(20.0),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: topSpacing), // Espacio para centrar un poco el contenido
            // view : si existe mostramos una imagen de asset
            assetImage != null
                ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CachedNetworkImage(
                      imageUrl: assetImage.assetName,
                      width: screenSize.width / 2,
                      height: screenSize.height / 2,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  )
                : Container(),
            // icon : un icono con animación
            iconData != null
                ? Container(
                    padding: iconPadding,
                    margin: iconMargin,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: Icon(iconData,
                        size: iconSize, color: colorIcon),
                  )
                    .animate(key: Key(titulo))
                    .fadeIn(duration: const Duration(milliseconds: 500))
                    .slideY(
                        begin: -0.2,
                        duration: const Duration(milliseconds: 500))
                : Container(),
            Text(titulo, style: estiloTitulo, textAlign: TextAlign.center),
            SizedBox(height: getResponsiveValue(
              context,
              mobile: 8.0,
              tablet: 10.0,
              desktop: 12.0,
            )),
            // text : un texto con animación
            Text(subtitulo, style: estiloSubTitulo, textAlign: TextAlign.center)
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 500))
                .slideY(
                    begin: 0.2, duration: const Duration(milliseconds: 500)),
            SizedBox(height: bottomSpacing),
          ],
        ),
      ),
    ));
  }
}
