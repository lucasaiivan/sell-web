import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/utils/fuctions.dart';

class ComponentApp extends StatelessWidget {
  const ComponentApp({super.key});
 
  @override
  Widget build(BuildContext context) {

    // set  
    return Container();
  }
  // view : grafico de barra para mostrar el progreso de carga de la app
  PreferredSize linearProgressBarApp({Color color = Colors.blue}) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(0.0),
        child: LinearProgressIndicator(
            minHeight: 6.0,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color)));
  }
  // view : grafico divisor estandar de la app 
  Divider divider({double thickness = 0.3}) {
    return Divider(
      thickness: thickness,height: 0, 
    );
  }
  // view : grafico punto divisor estandar de la app
  Widget dividerDot({double size = 4.0,Color color = Colors.black}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child:Icon(Icons.circle,size:size, color: color.withValues(alpha: 0.4)));
  }
  // view : imagen avatar del usuario
  Widget userAvatarCircle({ Color? background,IconData? iconData,bool empty=false,String urlImage='',String text = '', double radius = 20.0}) {
    
    // style
    Color? backgroundColor =background  ;
    // widgets
    late Widget avatar;
    late Widget iconDefault;
    if(empty){
      iconDefault = Container();
    }else if(urlImage == '' && text == ''){
      iconDefault = Icon(iconData??Icons.person_outline_rounded,color: Colors.white,size: radius*1.1 );
    }else if(urlImage == '' && text != ''){
      iconDefault = Text( text.substring( 0,1),style: const TextStyle(color: Colors.white));
    }else{
      iconDefault = Container();
    }
    
    // crear avatar
    avatar = urlImage == ''
      ? CircleAvatar(backgroundColor:backgroundColor,radius:radius, child: Center(child: iconDefault))
        : CachedNetworkImage(
          imageUrl: urlImage,
          placeholder: (context, url) => CircleAvatar(backgroundColor:backgroundColor,radius:radius, child:iconDefault),
          imageBuilder: (context, image) => CircleAvatar(backgroundImage: image,radius:radius),
          errorWidget: (context, url, error) {
            // return : un circleView con la inicial de nombre como icon 
            return CircleAvatar(
              backgroundColor: backgroundColor,
              radius:radius,
              child: Center(child: iconDefault),
              );
          },
    );

    return avatar;
  }
  // BUTTONS 
  Widget buttonAppbar({ required BuildContext context,Function() ?onTap,required String text,Color ?colorBackground ,Color ?colorAccent,IconData ?iconLeading ,IconData ?iconTrailing,EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0)}){ 
    
    // values default
    colorBackground ??= Theme.of(context).brightness == Brightness.dark?Colors.white:Colors.black;
    colorAccent ??= Theme.of(context).brightness == Brightness.dark?Colors.black:Colors.white;

    return Padding(
      padding: padding,
      child: Material(
        clipBehavior: Clip.antiAlias, 
        color: colorBackground,
        borderRadius: BorderRadius.circular(25),
        elevation: 0,
        child: InkWell(
          onTap:  onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 14, right: 20, top: 8, bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icon leading
                iconLeading==null?Container():Icon(iconLeading,color: colorAccent,size: 24),
                iconLeading==null?Container():const SizedBox(width:8),
                // text
                Flexible(child: Text(text,style: TextStyle(color: colorAccent,fontSize: 16 ),overflow: TextOverflow.ellipsis)), 
                iconTrailing==null?Container():const SizedBox(width:8), 
                iconTrailing==null?Container():Icon(iconTrailing,color: colorAccent,size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  } 
  Widget button( {bool defaultStyle = false,double elevation=0,double fontSize = 14,double width = double.infinity,bool disable = false, Widget? icon, String text = '',required dynamic onPressed,EdgeInsets padding =const EdgeInsets.symmetric(horizontal: 12, vertical: 12),Color? colorButton= Colors.blue,Color colorAccent = Colors.white , EdgeInsets margin =const EdgeInsets.symmetric(horizontal: 12, vertical: 12)}) {
     
    // button : personalizado
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Padding(
        key: ValueKey(disable), // To trigger animation on disable change
        padding: margin,
        child: SizedBox(
          width: width,
          child: ElevatedButton.icon(
            onPressed: disable ? null : onPressed,
            style: ElevatedButton.styleFrom(
              elevation: defaultStyle ? 0 : elevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              padding: padding,
              backgroundColor: colorButton,
              textStyle: TextStyle(color: colorAccent, fontWeight: FontWeight.w700),
            ),
            icon: icon ?? Container(),
            label: Text(
              text,
              style: TextStyle(color: colorAccent, fontSize: fontSize),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void showMessageAlertApp({required BuildContext context, required String title, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  
}

// AppMoneyInputFormatter : Formateador de texto para campos de dinero
// Este formateador se encarga de formatear el texto de un campo de texto para que se vea como un monto de dinero
class AppMoneyInputFormatter extends TextInputFormatter {

  final String symbol; 
  AppMoneyInputFormatter({this.symbol = ''});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,TextEditingValue newValue) { 
    
    // Eliminar cualquier cosa que no sea un número o una coma
    var newText = newValue.text.replaceAll(RegExp(r'[^0-9,]'), '');
    // elimina el 0 si es que esta al principioque existe de la primera posición
    if (newText.length > 1 && newText[0] == '0') {
      newText = newText.substring(1);
    }

    // Separar la parte entera y la parte decimal
    var parts = newText.split(',');
    var integerPart = parts[0];
    var decimalPart = parts.length > 1 ? parts[1] : '';

    // Limitar a 2 decimales
    if (decimalPart.length > 2) {
      decimalPart = decimalPart.substring(0, 2);
    }

    // Formatear la parte entera con puntos de miles
    var buffer = StringBuffer();
    for (var i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    // Construir el texto formateado
    var formattedText = buffer.toString();
    if (newText.contains(',')) {
      formattedText += ',$decimalPart';
    }

    // Añadir el signo de dólar al principio
    formattedText = '$symbol$formattedText';

    // Mantener la posición del cursor
    var selectionIndex = formattedText.length;
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
//  AppMoneyTextEditingController : Controlador de texto para campos de dinero
// Este controlador se encarga de manejar el valor de un campo de texto para que se vea como un monto de dinero
class AppMoneyTextEditingController extends TextEditingController {
  AppMoneyTextEditingController({String? value}) : super(text: value);

  // Método para obtener el valor como double
  double get doubleValue {
    String textWithoutCommas = text.replaceAll('.', '').replaceAll(',', '.').replaceAll('\$','');
    return double.tryParse(textWithoutCommas) ?? 0.0;
  }

  // Método para obtener el valor formateado como string
  String get formattedValue {
    return text;
  }
  // actualizar el valor del controlador
  void updateValue(double value) {
    // actualiza el nuevo valor teniendo en cuenta si tiene o no decimales
    text = Publications.getFormatoPrecio(value: value);
  }
}