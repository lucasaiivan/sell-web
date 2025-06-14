import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart'; 

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
  Widget buttonAppbar({ required BuildContext context,Function() ?onTap,required String text,Color ?colorBackground ,Color ?colorAccent,IconData ?iconLeading ,IconData ?iconTrailing,EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),bool textOpacity = false}) { 
    
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
                Flexible(child: Opacity(opacity:textOpacity?0.5:1,child: Text(text,style: TextStyle(color: colorAccent,fontSize: 16 ),overflow: TextOverflow.ellipsis))), 
                iconTrailing==null?Container():const SizedBox(width:8), 
                iconTrailing==null?Container():Icon(iconTrailing,color: colorAccent,size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  } 
  Widget button( {bool defaultStyle = false,double elevation=0,double fontSize = 14,double width = double.infinity,bool disable = false, Widget? icon, String text = '',required dynamic onPressed,EdgeInsets padding =const EdgeInsets.symmetric(horizontal: 12, vertical: 12),Color? colorButton= Colors.blue,Color colorAccent = Colors.white , EdgeInsets margin =const EdgeInsets.symmetric(horizontal: 12, vertical: 12), required BuildContext context, double? iconSize, Size? minimumSize}) {
     
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
              minimumSize: minimumSize,
            ),
            icon: icon != null && iconSize != null
                ? IconTheme(data: IconThemeData(size: iconSize), child: icon)
                : (icon ?? Container()),
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
  Widget buttonRoundAppBar({required void Function() onPressed,required BuildContext context,Widget ?child,required IconData icon,required EdgeInsets edgeInsets})  => Material(color: Colors.transparent,child: Center( child: Padding(padding: const EdgeInsets.all(8.0),child: Ink(decoration: ShapeDecoration(color: Brightness.dark==Theme.of(context).brightness?Colors.black:Colors.white,shape: const CircleBorder()), child: child==null?IconButton(icon: Icon(icon),color:Brightness.dark==Theme.of(context).brightness?Colors.white:Colors.black,onPressed: onPressed):child))));

  /// FloatingActionButton personalizado para 3 variantes: icono, texto o ambos.
  /// Usa FloatingActionButton.extended para texto o icono+texto, y FloatingActionButton para solo icono.
  Widget floatingActionButtonApp({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    Color? buttonColor,
    Color? textColor,
    double? size, // tamaño del botón
    bool widthInfinity = false,
  }) {
    final bool hasIcon = icon != null;
    final bool hasText = text != null && text.isNotEmpty;
    final double buttonSize = size ?? 56.0;
    final Color effectiveButtonColor = buttonColor ?? Colors.blue;
    final Color effectiveTextColor = textColor ?? Colors.white;

    if (hasText) {
      // FloatingActionButton.extended para texto o icono+texto
      return SizedBox(
        width: widthInfinity ? double.infinity : null,
        height: buttonSize,
        child: FloatingActionButton.extended(
          onPressed: onTap,
          backgroundColor: effectiveButtonColor,
          foregroundColor: effectiveTextColor,
          icon: hasIcon ? Icon(icon, size: buttonSize * 0.45) : null,
          label: Text(
            text,
            style: TextStyle(fontSize: buttonSize * 0.28, fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (hasIcon) {
      // Solo icono
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: FloatingActionButton(
          onPressed: onTap,
          backgroundColor: effectiveButtonColor,
          foregroundColor: effectiveTextColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonSize * 0.5)),
          child: Icon(icon, size: buttonSize * 0.5),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  
}

