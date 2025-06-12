import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart'; 
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/widgets.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/domain/entities/user.dart';
import '../providers/sell_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/auth_provider.dart'; 
import 'welcome_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {

  String _barcodeBuffer = '';
  DateTime? _lastKey;
  final FocusNode _focusNode = FocusNode();
  bool _showConfirmPurchaseButton = false; 

  void _onKey(KeyEvent event) async {  
    // Detecta un código de barras válido por velocidad de tipeo y enter
    if (event is KeyDownEvent && event.character != null) {
      final now = DateTime.now();
      // Si pasa más de 100ms entre teclas, se asume que es un nuevo escaneo
      if (_lastKey != null && now.difference(_lastKey!) > const Duration(milliseconds: 500)) {
        _barcodeBuffer = '';
      }
      _lastKey = now;
      // Agrega el carácter al buffer
      _barcodeBuffer += event.character!;
      // espera 100 ms antes de procesar el buffer
      await Future.delayed(const Duration(milliseconds: 200)).whenComplete(() {
        // Si el buffer tiene más de 6 caracteres, se asume que es un código de barras completo
        if (_barcodeBuffer.length > 6) {
          // Procesa el código de barras
          scanCodeProduct(code: _barcodeBuffer);
          // Limpia el buffer
          _barcodeBuffer = '';
        }
      }); 


    } 
  }

  void scanCodeProduct({required String code}) {

    final context = _focusNode.context;
    if (context == null) return;
    final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
    final homeProvider = Provider.of<SellProvider>(context, listen: false);
    final product = catalogueProvider.getProductByCode(code);
    
    if (product != null) {
      // agrega el producto al carrito de compras
      homeProvider.addProduct(product.copyWith()); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Producto no encontrado: $code')) );
    }
  }

   @override
  void initState() {
    super.initState();
    // sirve para que el teclado se enfoque automáticamente al iniciar la página 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void showModalBottomSheetSelectAccount() {

    // provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final SellProvider sellProvider = Provider.of<SellProvider>(context, listen: false); 

    // dialog 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (contextBottomSheet) {
        final accounts = authProvider.accountsAssociateds;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('Seleccionar cuenta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              if (accounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No tienes cuentas asociadas'),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  itemBuilder: (_, index) {

                    final account = accounts[index];

                    return buttonListTileItemCuenta(
                      perfilNegocio: account,
                      isSelected: sellProvider.selectedAccount.id  == account.id,
                      onTap: () {
                         sellProvider.selectAccount(account: account, context: context);
                         Navigator.of(context).pop();
                      }, 
                    );
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
 

  @override
  Widget build(BuildContext context) { 

    return Consumer2<SellProvider, CatalogueProvider>(
      builder: (_, sellProvider, catalogueProvider, _) {

        if(sellProvider.selectedAccount.id == '') {
          // Si no hay cuenta seleccionada, seleccionar la primera cuenta disponible
          return WelcomePage(
            onSelectAccount: (account) {
              // Selecciona la cuenta y recarga el catálogo
              sellProvider.selectAccount(account: account,context: context); 
            },
          );
        }
        return Scaffold(
          appBar: appbar(
            buildContext: context,
            provider: sellProvider,
          ),
          drawer: Container(), // ... // implementar drawer
          body: LayoutBuilder(
            builder: (context, constraints) {

              return Row(
                children: [
                  
                  /// [KeyboardListener] se utiliza para detectar y responder a eventos del Escaner de codigo de barra
                  Flexible(
                    child: Stack(
                      children: [
                        KeyboardListener(
                          focusNode: _focusNode,
                          autofocus: true,
                          onKeyEvent: _onKey,
                          child: body(provider: sellProvider),
                        ),
                        // floatingActionButton
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            backgroundColor: Colors.amber,
                            onPressed: () => showDialogQuickSale(provider: sellProvider),
                            child: const Icon(Icons.flash_on_rounded,
                            color: Colors.white)).animate( delay: const Duration(milliseconds: 0),).fade(),
                        ),
                      ],
                    ),
                  ),
                  //  drawerTicket para mostrar el ticket de venta
                  if (sellProvider.ticketView)
                    Stack(
                      children: [
                        drawerTicket(context),
                        // floatingActionButtonTicket 
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: floatingActionButtonTicket(provider: sellProvider).animate(
                            delay: const Duration(milliseconds: 0),
                          ).fade(),
                        ),
                      ],
                    ),

                ],
              );
            },
          ),
          //floatingActionButton: provider.ticketView ? floatingActionButtonTicket(provider: provider): floatingActionButton(provider: provider).animate( delay: const Duration( milliseconds:  0)).fade(),
        );
      },
    );
  }

  PreferredSizeWidget appbar({required BuildContext buildContext, required SellProvider provider}) { 

    return AppBar( 
      titleSpacing: 0.0, 
      title: ComponentApp().buttonAppbar( 
        context:  buildContext,
        onTap: (){
          // ... show modal bottom sheet
        }, 
        text: 'Vender',
        iconLeading: Icons.search,
        colorBackground: Theme.of(buildContext).colorScheme.outline.withValues(alpha: 0.1),//Colors.blueGrey.shade300.withOpacity(0.4),
        colorAccent: Theme.of(buildContext).textTheme.bodyLarge!.color?.withValues(alpha: 0.7),
        ),
      centerTitle: false,
      actions: [

        // text : mostrar cantidad de productos en el catalogo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Consumer<CatalogueProvider>(
            builder: (context, catalogueProvider, _) {
              final bool isLoading = catalogueProvider.products.isEmpty;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(buildContext).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isLoading ? 'Cargando...' : '${catalogueProvider.products.length} productos',
                  style: TextStyle(
                    color: Theme.of(buildContext).textTheme.bodyLarge!.color?.withOpacity(0.7),
                  ),
                ),
              );
            },
          ),
        ),
        // button : seleccionar cuentas administradas , icono con texto del nombre de la cuenta seleccionada
        TextButton(
          onPressed: () => showModalBottomSheetSelectAccount(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
          provider.selectedAccount.name.isNotEmpty ? provider.selectedAccount.name : 'Seleccionar cuenta',
          style: const TextStyle(color: Colors.blue),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.account_circle_rounded, color: Colors.blue),
            ],
          ),
        ),
        // button : salir de la cuenta si esque hay una cuenta seleccionada
        if (provider.selectedAccount.id.isNotEmpty) 
            TextButton.icon(
            icon: const SizedBox.shrink(),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text('Salir de la cuenta'),
              const SizedBox(width: 8),
              const Icon(Icons.logout_rounded),
              ],
            ),
            onPressed: provider.removeSelectedAccount,
          ),
      ],
    );
  } 
  Widget floatingActionButtonTicket({required SellProvider provider}) {
    final bool isConfirm = _showConfirmPurchaseButton;
    final String cobrarText = 'Cobrar ${provider.getTicket.listProduct.isEmpty ? '' : Publications.getFormatoPrecio(value: provider.getTicket.getTotalPrice)}';
    final String confirmarText = 'Confirmar venta';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final double ticketWidth = provider.ticketView ? (isMobile ? screenWidth : 400) : 0;
    final double minButtonWidth = 150;
    final double maxButtonWidth = ticketWidth > 0 ? ticketWidth - 40 : minButtonWidth; // padding

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: isConfirm ? maxButtonWidth : null,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size(isConfirm ? maxButtonWidth : minButtonWidth, 48),
            maximumSize: Size(isConfirm ? maxButtonWidth : double.infinity, 48),
          ),
          onPressed: () {
            if (isConfirm) {
              provider.discartTicket();
              setState(() {
                _showConfirmPurchaseButton = false;
              });
            } else {
              setState(() {
                _showConfirmPurchaseButton = true;
              });
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: Text(
              isConfirm ? confirmarText : cobrarText,
              key: ValueKey(isConfirm ? confirmarText : cobrarText),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget body({required SellProvider provider}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajusta el número de columnas según el ancho de pantalla para una experiencia uniforme
        int crossAxisCount;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 3; // Móvil, ítems grandes
        } else if (constraints.maxWidth < 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth < 1000) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6;
        }
        final List<ProductCatalogue> list = provider.selectedProducts.reversed.toList();
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          itemCount: list.length + 17,
          itemBuilder: (context, index) {
            if (index < list.length) {
              return ProductoItem(producto: list[index]);
            } else {
              return Card(elevation: 0, color: Colors.grey.withValues(alpha: 0.1));
            }
          },
        );
      },
    );
  }

  Widget drawerTicket(BuildContext context) {
    // values
    const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20, vertical: 1);
    final provider = Provider.of<SellProvider>(context);
    final ticket = provider.getTicket;

    // style
    Color borderColor = Colors.black;
    Color backgroundColor = Colors.white;
    const TextStyle textValuesStyle = TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold);
    const TextStyle textDescrpitionStyle = TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold);

    // widgets
    Widget dividerLinesWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Divider(
        color: borderColor,
        thickness: 0.5,
      ),
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return AnimatedContainer(
      width: provider.ticketView ? (isMobile ? screenWidth : 400) : 0,
      curve: Curves.fastOutSlowIn,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          
          elevation: 0,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borderColor.withValues(alpha: 0.7), width: 0.5),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: ListView(
            key: const Key('ticket'),
            shrinkWrap: false,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Ticket', textAlign: TextAlign.center, style: textDescrpitionStyle.copyWith(fontSize: 30, fontWeight: FontWeight.bold)),
              ),
              dividerLinesWidget,
              const SizedBox(height: 20),
              Padding(
                padding: padding,
                child: Row(
                  children: [
                    const Opacity(opacity: 0.7, child: Text('Productos:', style: textDescrpitionStyle)),
                    const Spacer(),
                    // Suma total de cantidades de todos los productos
                    Text(ticket.listProduct.fold<int>(0, (sum, item) => sum + item.quantity).toString(), style: textValuesStyle),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Lista de productos
              ...ticket.listProduct.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text(item.description, style: textValuesStyle)),
                    Text('x${item.quantity}', style: textValuesStyle),
                    const SizedBox(width: 8),
                    Text((item.salePrice * item.quantity).toStringAsFixed(2), style: textValuesStyle),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                color: Colors.green,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text('Total', style: textDescrpitionStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
                      const Spacer(),
                      const SizedBox(width: 12),
                      // Suma total considerando cantidades
                      Text(ticket.listProduct.fold<double>(0, (sum, item) => sum + (item.salePrice * (item.quantity))).toStringAsFixed(2), style: textValuesStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Aquí puedes agregar widgets para métodos de pago, descuentos, vuelto, etc.
            ],
          ),
        ),
      ),
    );
  }

  Widget widgetConfirmedPurchase(BuildContext context) {
    final provider = Provider.of<SellProvider>(context, listen: false);
    Color background = Colors.green.shade400;

    return Theme(
      data: ThemeData(brightness: Brightness.dark),
      child: Container(
        color: background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 60),
              const SizedBox(height: 12),
              const Text('¡Listo! Transacción exitosa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300)),
              const SizedBox(height: 20),
              Text('Total: \$${provider.getTicket.getTotalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  provider.setTicketView(false);
                  // Aquí puedes agregar lógica para reiniciar el estado si es necesario
                },
                child: const Text('Volver a vender', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ))
      );
  }

  void discartTicketAlertDialg() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Descartar ticket'),
          content: const Text('¿Estás seguro que desea descartar el ticket?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Provider.of<SellProvider>(this.context, listen: false).discartTicket();
                Navigator.of(context).pop();
              },
              child: const Text('Sí'),
            ),
          ],
        );
      },
    );
  }

  void showDialogQuickSale({required SellProvider provider}) {
 
    // Controllers
    final AppMoneyTextEditingController textEditingControllerAddFlashPrice =  AppMoneyTextEditingController( );
    final TextEditingController textEditingControllerAddFlashDescription = TextEditingController();
    final FocusNode myFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.only(left: 20, right: 8, top: 16, bottom: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          actionsPadding: const EdgeInsets.only(right: 8, bottom: 8),
          title: Row(
            children: [
              const Expanded(child: Text('Venta rápida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                splashRadius: 18,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    controller: textEditingControllerAddFlashPrice,
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                    inputFormatters: [
                        AppMoneyInputFormatter(symbol: '')
                      ],
                    decoration: InputDecoration(
                      labelText: "Precio",
                      prefixIcon: const Icon(Icons.attach_money_rounded),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                      border: OutlineInputBorder(borderSide:  BorderSide( )),
                      enabledBorder: OutlineInputBorder(borderSide:  BorderSide( ), )
                    ),
                    style: const TextStyle(fontSize: 16.0),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    focusNode: myFocusNode,
                    controller: textEditingControllerAddFlashDescription,
                    decoration: InputDecoration(
                      labelText: "Descripción (opcional)",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      border: OutlineInputBorder(borderSide:  BorderSide( )),
                        enabledBorder: OutlineInputBorder(borderSide:  BorderSide( ), )
                    ),
                    style: const TextStyle(fontSize: 16.0),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (textEditingControllerAddFlashPrice.doubleValue <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('El precio debe ser mayor a cero')),
                        );
                        return;
                      }
                      provider.addQuickProduct(
                        description: textEditingControllerAddFlashDescription.text,
                        salePrice: textEditingControllerAddFlashPrice.doubleValue,
                      );
                      textEditingControllerAddFlashPrice.clear();
                      textEditingControllerAddFlashDescription.clear();
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.only(right:20,left:20, bottom:20),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom( 
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (textEditingControllerAddFlashPrice.doubleValue <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('El precio debe ser mayor a cero')),
                      );
                      return;
                    }
                    provider.addQuickProduct(
                      description: textEditingControllerAddFlashDescription.text,
                      salePrice: textEditingControllerAddFlashPrice.doubleValue,
                    );
                    textEditingControllerAddFlashPrice.clear();
                    textEditingControllerAddFlashDescription.clear();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Agregar', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        );
      },
    );  
  }

  /// Muestra una cuenta con un icono check si está seleccionada.
  Widget buttonListTileItemCuenta({
    required ProfileAccountModel perfilNegocio,
    required bool isSelected,
    required VoidCallback onTap, 
  }) {
    if (perfilNegocio.id == '') return Container();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      leading: CircleAvatar(
        backgroundColor: Colors.black26,
        backgroundImage: (perfilNegocio.image.isNotEmpty && perfilNegocio.image.contains('https://'))
            ? NetworkImage(perfilNegocio.image)
            : null,
        child: (perfilNegocio.image.isEmpty)
            ? Text(perfilNegocio.name.isNotEmpty ? perfilNegocio.name[0] : '?',
                style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(perfilNegocio.name, style: const TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
          : null,
      onTap: onTap,
    );
  }
}


















class ProductoItem extends StatefulWidget {
  final ProductCatalogue producto;

  const ProductoItem({super.key, required this.producto});

  @override
  State<ProductoItem> createState() => _ProductoItemState();
}
class _ProductoItemState extends State<ProductoItem> { 

  @override
  Widget build(BuildContext context) {
    //  values 
    final String alertStockText = widget.producto.stock
      ? (widget.producto.quantityStock >= 0
        ? widget.producto.quantityStock <= widget.producto.alertStock
          ? 'Stock bajo'
          : ''
        : 'Sin stock')
      : '';

    // aparición animada
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Stack(  
        children: [
          // view : alert stock, image and info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              alertStockText == ''
                  ? Container()
                  : Container(
                      width: double.infinity,
                      color: Colors.red,
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(alertStockText,style: const TextStyle(color: Colors.white,fontSize: 10,fontWeight: FontWeight.bold)),
                      ))),
              // Cambiar Flexible por Expanded para evitar error de argumentos
                Expanded(
                flex: 2,
                child: contentImage(),
                ),
              contentInfo(),
          ],
          ),
          // view : selected
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                mouseCursor: MouseCursor.uncontrolled,
                onTap: () {
                  final originalContext = context; // <-- Guardar el contexto original
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      int cantidad = widget.producto.quantity;
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            backgroundColor: Theme.of(dialogContext).colorScheme.surface,
                            title: Text(widget.producto.description, style: Theme.of(dialogContext).textTheme.titleLarge),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.producto.image.isNotEmpty)
                                  Center(
                                  child: SizedBox(
                                      width: 300,
                                      height: 300,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                      widget.producto.image, 
                                      fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  ),
                                const SizedBox(height: 16),
                                Text('Código: ${widget.producto.code}', style: Theme.of(dialogContext).textTheme.bodyMedium),
                                Text('Precio: [200m${Publications.getFormatoPrecio(value: widget.producto.salePrice)}[0m', style: Theme.of(dialogContext).textTheme.bodyMedium),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Text('Cantidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: cantidad > 1 ? () => setState(() => cantidad--) : null,
                                      color: Theme.of(dialogContext).colorScheme.primary,
                                    ),
                                    Text('$cantidad', style: Theme.of(dialogContext).textTheme.titleMedium),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => setState(() => cantidad++),
                                      color: Theme.of(dialogContext).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar'),
                                style: TextButton.styleFrom(foregroundColor: Theme.of(dialogContext).colorScheme.error),
                                onPressed: () {
                                  Provider.of<SellProvider>(originalContext, listen: false).removeProduct(widget.producto);
                                  Navigator.of(originalContext).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed: () => Navigator.of(originalContext).pop(),
                              ),
                              FilledButton(
                                child: const Text('Guardar'),
                                onPressed: () {
                                  Provider.of<SellProvider>(originalContext, listen: false).addProduct(
                                    widget.producto.copyWith(quantity: cantidad),
                                    replaceQuantity: true,
                                  );
                                  Navigator.of(originalContext).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },  
              ),
            ),
          ),
          // view : cantidad de productos seleccionados
          widget.producto.quantity==1 ?  Container()
          :Positioned(
            top:5,
            right:5,
            child: CircleAvatar(
              backgroundColor: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: CircleAvatar(  
                  backgroundColor: Colors.white,
                  child: Text(widget.producto.quantity.toString(),style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS COMPONETS

  Widget contentImage() {
    // var
    String description = widget.producto.description != ''
        ? widget.producto.description.length >= 3
            ? widget.producto.description.substring(0, 3)
            : widget.producto.description.substring(0, 1)
        : Publications.getFormatoPrecio(
            value: widget.producto.salePrice * widget.producto.quantity);
    return widget.producto.image != "" && !widget.producto.local
        ? SizedBox(
            width: double.infinity,
            child: CachedNetworkImage(
              fadeInDuration: const Duration(milliseconds: 200),
              fit: BoxFit.cover,
              imageUrl: widget.producto.image,
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: Center(
                  child: Text(description, style: const TextStyle(fontSize: 24.0, color: Colors.grey,overflow: TextOverflow.clip )),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[100],
                child: Center(
                  child: Text(description,
                      style:  const TextStyle(fontSize: 24.0, color: Colors.grey,overflow: TextOverflow.clip)),
                ),
              ),
            ),
          )
        : Container(
            color: Colors.grey[100],
            child: Center(
              child: Text(description,
                  style: const TextStyle(fontSize: 24.0, color: Colors.grey,overflow: TextOverflow.clip)),
            ),
          );
  }

  Widget contentInfo() {
    return widget.producto.description == ''
        ? Container()
        : Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.producto.description,style: const TextStyle(fontWeight: FontWeight.normal,color: Colors.grey ,overflow:TextOverflow.ellipsis),maxLines:1),
                Text( Publications.getFormatoPrecio(value: widget.producto.salePrice),
                    style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 17.0,color: Colors.black),
                    overflow: TextOverflow.clip,
                    softWrap: false),
              ],
            ),
          );
  }
}