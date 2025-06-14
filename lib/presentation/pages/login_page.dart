import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/widgets/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_data_app_provider.dart';

class LoginPage extends StatelessWidget {
  final AuthProvider authProvider;
  const LoginPage({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
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
          // button : cambiar el brillo del tema
          Positioned(
            top: 20,
            right: 20,
            child: Consumer<ThemeDataAppProvider>(
              builder: (context, themeProvider, _) => Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Cambiar brillo',
                  onPressed: () => themeProvider.toggleTheme(),
                ),
              ),
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
  Widget build(BuildContext context) {
    
    final bool darkMode = Theme.of(context).brightness == Brightness.dark;
    TextStyle defaultStyle = TextStyle(color: darkMode ? Colors.white : Colors.black,fontSize: 12);
    TextStyle linkStyle = const TextStyle(color: Colors.blue);
    RichText text = RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: defaultStyle,
        children: <TextSpan>[
          const TextSpan(text: 'Al iniciar en INICIAR SESIÓN, usted ha leído y acepta nuestros '),
          TextSpan(
              text: 'Términos y condiciones de uso',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  final Uri url = Uri.parse(
                      'https://sites.google.com/view/sell-app/t%C3%A9rminos-y-condiciones-de-uso');
                  if (!await launchUrl(url)) throw 'Could not launch $url';
                }),
          const TextSpan(text: ' así también como la '),
          TextSpan(
              text: 'Política de privacidad',
              style: linkStyle,
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
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [ 
                  // CheckboxListTile : aceptar términos y condiciones
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CheckboxListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      selectedTileColor: Colors.transparent,
                      tileColor: Colors.transparent,
                      checkColor: Colors.white,
                      activeColor: Colors.blue,
                      title: text,
                      value: _acceptPolicy,
                      onChanged: (value) {
                        setState(() {
                          _acceptPolicy = value ?? false;
                        });
                      },
                    ),
                  ), 
                  // ElevatedButton : Iniciar sesión con Google
                  ComponentApp().button(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),   
                    context: context,
                    text: "INICIAR SESIÓN CON GOOGLE", 
                    onPressed: _acceptPolicy
                        ? () async {
                            await widget.authProvider.signInWithGoogle();
                          }
                        : null,
                  ),
                  // ElevatedButton : Iniciar como invitado
                  ComponentApp().button(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    context: context,
                    colorButton: Colors.blueGrey,
                    text: "ENTRAR COMO INVITADO",
                    onPressed: () async {
                      await widget.authProvider.signInAsGuest();
                    },
                  ),
                ],
              ),
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class OnboardingIntroductionApp extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  OnboardingIntroductionApp({this.colorAccent = Colors.deepPurple,this.colorText = Colors.white,super.key});

  late final Color colorAccent;
  late final Color colorText;

  @override
  State<OnboardingIntroductionApp> createState() => _OnboardingIntroductionAppState();
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
  int index = 0 ;
  late List<Widget> widgets;

  // fuction  : maneja el evento de toque IZQUIERDO que cambian los valores de los indicadores de progreso y cambia la vista del item
  void leftTouch(){ 
    //  primer item : si el primer item esta en 0.0 y el segundo y tercer item estan en 0.0 entonces el primer item pasa a 1.0
    if(indicatorProgressItem01 >= 0.0  &&  indicatorProgressItem02 == 0.0 &&  indicatorProgressItem03 == 0.0 ){
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index=0;  // siguiente vista
    }
    // segundo item : si el primer item esta en 1.0 y el segundo item esta en 0.0 y el tercer item esta en 0.0 entonces el segundo item pasa a 1.0
    else if( indicatorProgressItem01 == 1.0 &&  indicatorProgressItem02 >= 0.0 &&  indicatorProgressItem03 == 0.0 ){
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index=1; //  siguiente vista
    }
    //  tercer item : si el primer item esta en 1.0 y el segundo item esta en 1.0 y el tercer item esta en 0.0 entonces el tercer item pasa a 1.0
    else if( indicatorProgressItem01 == 1.0 &&  indicatorProgressItem02 == 1.0 &&  indicatorProgressItem03 >= 0.0 ){
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index=2; //  siguiente vista
    } 
    // vuelve a la vista al princio
    else{
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index=0;
    }
  }
  // fuction  : maneja el evento de toque DERECHO que cambian los valores de los indicadores de progreso
  void rightTouch() {
    // primer item : si el primer item esta en 0.0 y el segundo y tercer item estan en 0.0 entonces el primer item pasa a 1.0
    if (indicatorProgressItem01 <= 1.00 && indicatorProgressItem02 == 0.0 && indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 1; // siguiente vista
    }
    // segundo item : si el primer item esta en 1.0 y el segundo item esta en 0.0 y el tercer item esta en 0.0 entonces el segundo item pasa a 1.0
    else if (indicatorProgressItem02 <= 1.00 && indicatorProgressItem01 > 0.0 && indicatorProgressItem03 == 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 1.0;
      indicatorProgressItem03 = 0.0;
      index = 2; // siguiente vista
    }
    // tercer item  : si el primer item esta en 1.0 y el segundo item esta en 1.0 y el tercer item esta en 0.0 entonces el tercer item pasa a 1.0
    else if (indicatorProgressItem03 <= 1.00 && indicatorProgressItem01 > 0.0 && indicatorProgressItem02 > 0.0) {
      indicatorProgressItem01 = 1.0;
      indicatorProgressItem02 = 1.0;
      indicatorProgressItem03 = 1.0;
      index = 3; // siguiente vista
    }// vuelve a la vista al principio
    else {
      indicatorProgressItem01 = 0.0;
      indicatorProgressItem02 = 0.0;
      indicatorProgressItem03 = 0.0;
      index = 0;
    } 
  }

  void positionIndicatorLogic(){
    // logica de los indicadores de posicion que cambiar cada sierto tiempo
    timer = Timer.periodic( const Duration(microseconds: 50000), (timer) {
      try{
        setState(() {
        if(indicatorProgressItem01<1 ){
          if( indicatorProgressItem01 >=0.1 && indicatorProgressItem01 <= 0.8 ){indicatorProgressItem01 += 0.02;}
          else{indicatorProgressItem01 += 0.01;}
          index=0;
        }
        if( indicatorProgressItem02<1 && indicatorProgressItem01>=1 ){
          if( indicatorProgressItem02 >=0.1 && indicatorProgressItem02 <= 0.8 ){indicatorProgressItem02 += 0.02;}
          else{indicatorProgressItem02 += 0.01;}
          index=1;
        }
        if( indicatorProgressItem03<1 && indicatorProgressItem02>=1 ){
          if( indicatorProgressItem03 >=0.1 && indicatorProgressItem03 <= 0.8 ){indicatorProgressItem03 += 0.02;}
          else{indicatorProgressItem03 += 0.01;}
          index=2;
        }
        if( indicatorProgressItem01>=1 && indicatorProgressItem02>=1 && indicatorProgressItem03>=1 ){
          indicatorProgressItem01=0.0;
          indicatorProgressItem02=0.0;
          indicatorProgressItem03=0.0;
        }

      });
      // ignore: empty_catches
      }catch(e){ }
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
    darkMode = Theme.of(context).brightness==Brightness.dark;
    screenSize = MediaQuery.of(context).size;
 
    // lista de widgets con las vistas
    widgets = [
      pageView( context:context,colorContent:Colors.transparent,textColor: Colors.white,colorIcon: Colors.orange.shade300,iconData: Icons.monetization_on,titulo:"VENTAS",subtitulo:"Registra tus ventas de una forma simple 😊"),
      pageView( context:context,colorContent:Colors.transparent,textColor: Colors.white,colorIcon: Colors.teal.shade300,iconData: Icons.analytics_outlined,titulo:"TRANSACCIONES",subtitulo:"Observa las transacciones que has realizado 💰"),
      pageView( context:context,colorContent:Colors.transparent,textColor: Colors.white,colorIcon: Colors.deepPurple.shade300,iconData: Icons.category,titulo:"CATÁLOGO",subtitulo:"Arma tu catálogo y controla el stock de tus productos \n 🍫🍬🥫🍾"),
    ];

    String uriImage = index==0?sellImagen:index==1?transactionImage:catalogueImage;


    
    return Stack(
      children: [
        // Imagen background
        ClipRRect( borderRadius: BorderRadius.circular(10.0), child: Opacity(opacity: 0.8,child: Image(image: AssetImage(uriImage),width: double.infinity,height:double.infinity,fit: BoxFit.cover))) ,
        // view : contenidos
        Column(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 12),
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
                            backgroundColor: darkMode?Colors.white12:Colors.black12,
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
                            backgroundColor: darkMode?Colors.white12:Colors.black12,
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
                            backgroundColor: darkMode?Colors.white12:Colors.black12,
                            value: indicatorProgressItem03,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(child: widgets[index] ),
          ],
        ),
        // controlamos los toques del usuario
        Row(
          children: [
            // toque izquierdo
            Flexible(child: InkWell(onTap: leftTouch,highlightColor: Colors.transparent,splashColor: Colors.transparent,focusColor: Colors.transparent,hoverColor: Colors.transparent,)),
            //  toque derecho
            Flexible(child: InkWell(onTap: rightTouch,highlightColor: Colors.transparent,splashColor: Colors.transparent,focusColor: Colors.transparent,hoverColor: Colors.transparent,)),
            //  touch
          ],
        ),
        
      ],
    );
  }

  Widget pageView({required BuildContext context,Color ?colorContent,Color textColor = Colors.black, AssetImage ?assetImage,IconData ?iconData,Color ?colorIcon, String titulo="",String subtitulo=""}) {

    // Definimos los estilos
    colorContent ??= Theme.of(context).brightness==Brightness.dark?Colors.white:Colors.black;
    colorIcon ??= colorContent;
    final estiloTitulo = TextStyle(fontSize: 50.0, fontWeight: FontWeight.bold,color: textColor);
    final estiloSubTitulo = TextStyle(fontSize: 24.0,fontWeight: FontWeight.bold,color: textColor.withValues(alpha: 0.8));

    return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              const Spacer(),
              // view : si existe mostramos una imagen de asset
                assetImage != null
                  ? Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: CachedNetworkImage(
                    imageUrl: assetImage.assetName,
                    width: screenSize.width / 2,
                    height: screenSize.height / 2,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const CircularProgressIndicator(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  )
                  : Container(),
              // icon : un icono con animion
                iconData != null
                  ? Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                    child: Icon(iconData,size: screenSize.height * 0.07,color: colorIcon),
                  ).animate(key: Key(titulo)).fadeIn(duration: const Duration(milliseconds: 500)).slideY(begin: -0.2, duration: const Duration(milliseconds: 500))
                  : Container(),
              Text(titulo,style: estiloTitulo,textAlign: TextAlign.center),
              const SizedBox(height: 12.0),
              // text : un texto con animacion
              Text(subtitulo,style: estiloSubTitulo,textAlign: TextAlign.center).animate().fadeIn(duration: const Duration(milliseconds: 500)).slideY(begin: 0.2, duration: const Duration(milliseconds: 500)),
              const SizedBox(height: 12.0),
              const Spacer(),
            ],
          ),
        ));
  }


 
}
