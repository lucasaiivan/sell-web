
import 'package:sellweb/core/services/thermal_printer_http_service.dart';
import 'package:sellweb/core/widgets/buttons/app_bar_button.dart';
import 'package:sellweb/presentation/widgets/cash_register_status_widget.dart';
import 'package:web/web.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/core/widgets/dialogs/add_product_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/quick_sale_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/product_edit_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/ticket_options_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/printer_config_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/last_ticket_dialog.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/widgets/component_app_legacy.dart';
import '../providers/sell_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart'; 
import '../providers/theme_data_app_provider.dart'; 
import 'welcome_page.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  // variables
  String _barcodeBuffer = '';
  DateTime? _lastKey;
  final FocusNode _focusNode = FocusNode();
  bool _showConfirmedPurchase = false;

  @override
  void initState() {
    super.initState();
    // si es web ?
    if (html.window.location.href.contains('web')) {
      // Enfoca el nodo de entrada para que el teclado se muestre automáticamente
      _focusNode.requestFocus();
    }
    // Cambia el título de la pestaña al iniciar la página principal
    html.document.title = 'Punto de venta';
    // sirve para que el teclado se enfoque automáticamente al iniciar la página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      Provider.of<PrinterProvider>(context, listen: false).refreshStatus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SellProvider, CatalogueProvider>(
      builder: (_, sellProvider, catalogueProvider, __) {
        // Si no hay cuenta seleccionada, mostrar la página de bienvenida
        if (sellProvider.profileAccountSelected.id == '') {
          // provider : authProvider y catalogueProvider
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          final catalogueProvider =
              Provider.of<CatalogueProvider>(context, listen: false);

          return WelcomePage(
            onSelectAccount: (account) async {
              // Selecciona la cuenta y recarga el catálogo
              await sellProvider.initAccount(
                  account: account, context: context);
              // Si es demo, cargar productos demo

              if (account.id == 'demo' &&
                  authProvider.user?.isAnonymous == true) {
                final demoProducts =
                    authProvider.getUserAccountsUseCase.getDemoProducts();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  catalogueProvider.loadDemoProducts(demoProducts);
                });
              }
            },
          );
        }
        // account demo : Si la cuenta seleccionada es demo y usuario anónimo, cargar productos demo
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (sellProvider.profileAccountSelected.id == 'demo' &&
            authProvider.user?.isAnonymous == true &&
            catalogueProvider.products.isEmpty) {
          final demoProducts =
              authProvider.getUserAccountsUseCase.getDemoProducts();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            catalogueProvider.loadDemoProducts(demoProducts);
          });
        }
        return Scaffold(
          appBar: appbar(
            buildContext: context,
            provider: sellProvider,
          ),
          drawer: drawer,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Flexible(
                    child: Stack(
                      children: [
                        /// [KeyboardListener] se utiliza para detectar y responder a eventos del Escaner de codigo de barra
                        KeyboardListener(
                          focusNode: _focusNode,
                          autofocus: true,
                          onKeyEvent: _onKey,
                          child: body(provider: sellProvider),
                        ),
                        // floatingActionButtonBody
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: floatingActionButtonBody(
                              sellProvider: sellProvider),
                        ),
                      ],
                    ),
                  ),
                  // drawerTicket view : visualización del ticket con los datos de la compra
                  if (!isMobile(context) &&
                          sellProvider.ticket.getProductsQuantity() != 0 ||
                      (isMobile(context) && sellProvider.ticketView))
                    drawerTicket(context),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // FUCTIONS
  void _onKey(KeyEvent event) async {
    // Detecta un código de barras válido por velocidad de tipeo y enter
    if (event is KeyDownEvent && event.character != null) {
      final now = DateTime.now();
      // Si pasa más de 100ms entre teclas, se asume que es un nuevo escaneo
      if (_lastKey != null &&
          now.difference(_lastKey!) > const Duration(milliseconds: 500)) {
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

  void scanCodeProduct({required String code}) async {
    final context = _focusNode.context;
    if (context == null) return;
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final homeProvider = Provider.of<SellProvider>(context, listen: false);
    final product = catalogueProvider.getProductByCode(code);
    if (product != null) {
      // Si se encuentra el producto en el catálogo, agregarlo al ticket
      homeProvider.addProductsticket(product.copyWith());
    } else {
      // Si no se encuentra el producto en el catálogo, buscar en la base pública
      final publicProduct =
          await catalogueProvider.getPublicProductByCode(code);
      if (publicProduct != null) {
        // Si se encuentra un producto público, mostrar el diálogo para agregarlo al ticket
        final productCatalogue = publicProduct.convertProductCatalogue();
        if (mounted) {
          showAddProductDialog(context, product: productCatalogue);
        }
      } else {
        // Si no se encuentra el producto, mostrar un diálogo de [producto no encontrado]
        if (mounted) {
          showAddProductDialog(context,
              isNew: true, product: ProductCatalogue(id: code, code: code));
        }
      }
    }
  }

  /// Muestra un AlertDialog temporal con mensaje de error y opciones para crear o agregar producto.
  /// Se cierra automáticamente después de [duracion] milisegundos si no se elige una acción.
  Future<void> showDialogProductoNoEncontrado(BuildContext context,
      {required String code}) async {
    bool accionRealizada = false;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        // title : titulo del dialog y button cerrar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(code,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                accionRealizada = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mensaje mejorado: No se encontró el producto
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.orange.withValues(alpha: 0.15),
              child: const Icon(Icons.search_off_rounded,
                  color: Colors.orange, size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Producto no encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // button : cancelar
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                  },
                ),
                // button : Agregar producto
                ElevatedButton(
                  child: const Text('Crear producto'),
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                    // TODO: Implementa la lógica para crear producto
                    // showDialogCrearProducto(context);
                  },
                ),
              ],
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    // Si el usuario no presionó ninguna acción, cerrar automáticamente después de la duración
    if (!accionRealizada) {
      await Future.delayed(Duration(milliseconds: 3000));
      // ignore: use_build_context_synchronously
      if (Navigator.of(context).canPop()) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop();
      }
    }
  }

  void showModalBottomSheetSelectAccount() {
    // provider
    final SellProvider sellProvider =
        Provider.of<SellProvider>(context, listen: false);

    // dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (contextBottomSheet) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final accounts =
            authProvider.getUserAccountsUseCase.getAccountsWithDemo(
          authProvider.accountsAssociateds,
          isAnonymous: authProvider.user?.isAnonymous == true,
        );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('Seleccionar cuenta',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
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
                      isSelected:
                          sellProvider.profileAccountSelected.id == account.id,
                      onTap: () {
                        // Selecciona la cuenta y cierra el modal
                        sellProvider.initAccount(
                            account: account, context: context);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              // Botón para salir de la cuenta si hay una seleccionada
              if (sellProvider.profileAccountSelected.id.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Salir de la cuenta'),
                    onPressed: () async {
                      await sellProvider.removeSelectedAccount();
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pop();
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Returns the AppBar for the SellPage, using the current CatalogueProvider.
  PreferredSizeWidget appbar(
      {required BuildContext buildContext, required SellProvider provider}) {
    final catalogueProvider = Provider.of<CatalogueProvider>(buildContext);
    final bool isLoading = catalogueProvider.isLoading;
    final bool isEmpty = !isLoading && catalogueProvider.products.isEmpty;
    // Si no hay productos y ya cargó, ocultar el buttonAppbar
    return AppBar(
      toolbarHeight: 70,
      titleSpacing: 0,
      // Agregar espacio adicional desde la barra de estado
      elevation: 0,
      leading: Container(),
      scrolledUnderElevation: 0,
      // Usar flexibleSpace para controlar mejor el espaciado
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(
              top: 20.0,
              bottom: 12,
              left: 12,
              right: 12), // Espacio adicional desde la barra de estado
          child: Row(
            children: [
              // Avatar con padding personalizado
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: ComponentApp().userAvatarCircle(
                    urlImage: provider.profileAccountSelected.image,
                    text: provider.profileAccountSelected.name,
                    radius: 18,
                  ),
                ),
              ),
              // Botón de búsqueda expandido
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 8.0),
                child: ComponentApp().searchButtonAppBar(
                  height: 40,
                  context: buildContext,
                  onPressed: (isLoading || isEmpty)
                      ? () {}
                      : () => showModalBottomSheetSelectProducts(buildContext),
                  icon: isLoading || isEmpty
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(buildContext)
                                  .colorScheme
                                  .primaryContainer))
                      : Icon(Icons.search_rounded),
                  label: isLoading
                      ? 'Cargando...'
                      : isEmpty
                          ? 'No hay productos disponibles'
                          : 'Buscar productos',
                  color: Theme.of(buildContext).colorScheme.primaryContainer,
                  textColor:
                      Theme.of(buildContext).colorScheme.onPrimaryContainer,
                  iconColor:
                      Theme.of(buildContext).colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              // Acciones del AppBar
              Row(
                children: [
                  // button : botón de estado de la impresora
                  Consumer<PrinterProvider>(
                    builder: (context, printerProvider, __) {
                      final isConnected = printerProvider.isConnected;
                      return AppBarButtonCircle(
                        icon: isConnected
                            ? Icons.print_outlined
                            : Icons.print_disabled_outlined,
                        tooltip: isConnected
                            ? 'Impresora conectada y lista\nToca para configurar'
                            : 'Impresora no disponible\nToca para configurar conexión',
                        onPressed: () =>
                            _showPrinterConfigDialog(buildContext),
                        backgroundColor: isConnected
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha:0.07),
                        iconColor: isConnected
                            ? Colors.green.shade700
                            : Colors.orange.shade500,
                      )
                          .animate(
                            // Añadir animación sutil cuando está conectada
                            effects: isConnected
                                ? [
                                    const ScaleEffect(
                                      duration: Duration(milliseconds: 1500),
                                      curve: Curves.easeInOut,
                                      begin: Offset(1.0, 1.0),
                                      end: Offset(1.05, 1.05),
                                    ),
                                  ]
                                : [],
                          )
                          .animate(
                            delay: const Duration(milliseconds: 1500),
                            effects: isConnected
                                ? [
                                    const ScaleEffect(
                                      duration: Duration(milliseconds: 1500),
                                      curve: Curves.easeInOut,
                                      begin: Offset(1.05, 1.05),
                                      end: Offset(1.0, 1.0),
                                    ),
                                  ]
                                : [],
                          );
                    },
                  ),
                  
                  // button : último ticket vendido
                  Consumer<SellProvider>(
                    builder: (context, sellProvider, __) {
                      final hasLastTicket = sellProvider.lastSoldTicket != null;
                      return AppBarButtonCircle(
                        icon: Icons.receipt_long_rounded,
                        tooltip: hasLastTicket
                            ? 'Ver último ticket\nToca para ver detalles y reimprimir'
                            : 'No hay tickets recientes',
                        onPressed: hasLastTicket
                            ? () => _showLastTicketDialog(
                                buildContext, sellProvider)
                            : null,
                        backgroundColor: hasLastTicket ? Theme.of(buildContext).colorScheme.primaryContainer.withValues(alpha: 0.4): Colors.grey.withValues(alpha:0.15),
                        iconColor: hasLastTicket? Theme.of(buildContext).colorScheme.primary: Colors.grey.shade400,
                      );
                    },
                  ),

                  // button : administrar caja
                  CashRegisterStatusWidget(),

                  // Botón de descartar ticket (existente)
                  ((isMobile(buildContext) && provider.ticketView) ||
                          (!isMobile(buildContext) &&
                              provider.ticket.getProductsQuantity() > 0))
                      ? Padding(
                          padding:
                              const EdgeInsets.only(right: 8.0, left: 12.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Descartar ticket'),
                            onPressed: discartTicketAlertDialg,
                          ),
                        )
                      : Container(),
                ],
              )
            ],
          ),
        ),
      ),
      // Remover las propiedades leading, title y actions ya que están en flexibleSpace
      centerTitle: false,
    );
  }

  Widget get drawer {
    // provider
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    // theme
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // button : button personalizado que abre el modal de selección de cuenta administradas
                  accoutsAssociatedsButton(
                    context: context,
                    onTap: showModalBottomSheetSelectAccount,
                  ),
                  const Spacer(),
                  // button : cambiar brillo del temae
                  IconButton(
                    icon: theme.brightness == Brightness.light
                        ? const Icon(Icons.dark_mode_rounded)
                        : const Icon(Icons.light_mode_rounded),
                    tooltip: 'Cambiar brillo',
                    onPressed: () {
                      Provider.of<ThemeDataAppProvider>(context, listen: false)
                          .toggleTheme();
                    },
                  ),
                ],
              ),
            ),
            // listitle : perfil de negocio, nombre de la cuenta seleccionada y avatar
            ListTile(
              leading: ComponentApp().userAvatarCircle(
                  urlImage: sellProvider.profileAccountSelected.image,
                  text: sellProvider.profileAccountSelected.name),
              title: Text(sellProvider.profileAccountSelected.name,
                  style: const TextStyle(fontSize: 18)),
              subtitle: Text(sellProvider.profileAccountSelected.province,
                  style: const TextStyle(fontSize: 14)),
              onTap: () => showModalBottomSheetSelectAccount(),
            ),
            // view : Mas funciones en nuesta app
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(thickness: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 8),
                  Text(
                    '¡Descubre todas las funciones en nuestra app móvil!',
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.link_rounded,
                          size: 22, color: Colors.white),
                      label: const Text('Ver en Play Store'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () {
                        html.window.open(
                          'https://play.google.com/store/apps/details?id=tu.paquete.app', // Reemplaza con tu URL real
                          '_blank',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Botones para la vista del ticket. showClose controla si se muestra el botón de cerrar (solo en móvil).
  Widget floatingActionButtonTicket(
      {required SellProvider provider, bool showClose = true}) {
    final String confirmarText = 'Confirmar venta';
    if (_showConfirmedPurchase) return const SizedBox.shrink();
    return Row(
      children: [
        if (showClose)
          ComponentApp()
              .floatingActionButtonApp(
                onTap: () {
                  provider.setTicketView(false);
                },
                widthInfinity: true,
                icon: Icons.close_rounded,
                buttonColor: Colors.grey.withValues(alpha: 0.8),
              )
              .animate(delay: const Duration(milliseconds: 0))
              .fade(),
        if (showClose) const SizedBox(width: 8),
        ComponentApp()
            .floatingActionButtonApp(
              onTap: () async {
                // Mostrar confirmación de venta completada inmediatamente
                setState(() {
                  _showConfirmedPurchase = true;
                });

                // Si el checkbox está activo, procesar la impresión/generación de tickets
                if (provider.shouldPrintTicket) {
                  // Verificar si hay impresora conectada
                  final printerService = ThermalPrinterHttpService();
                  await printerService.initialize();

                  if (printerService.isConnected) {
                    // Si hay impresora conectada, imprimir directamente el ticket real
                    try {
                      // Determinar método de pago primero
                      String paymentMethod = 'Efectivo';
                      switch (provider.ticket.payMode) {
                        case 'mercadopago':
                          paymentMethod = 'Mercado Pago';
                          break;
                        case 'card':
                          paymentMethod = 'Tarjeta Déb/Créd';
                          break;
                        default:
                          paymentMethod = 'Efectivo';
                      }

                      // Preparar datos del ticket
                      final products = provider.ticket.listPoduct.map((item) {
                        final product = item is Map ? item : item.toMap();
                        return {
                          'quantity': product['quantity'].toString(),
                          'description': product['description'],
                          'price': (product['salePrice'] * product['quantity'])
                              .toDouble(),
                        };
                      }).toList();

                      // Debug: mostrar datos que se van a enviar
                      if (kDebugMode) {
                        print('=== DEBUG PRINTER DATA ===');
                        print(
                            'Business Name: ${provider.profileAccountSelected.name}');
                        print('Products: $products');
                        print('Total: ${provider.ticket.getTotalPrice}');
                        print('Payment Method: $paymentMethod');
                        print('=========================');
                      }

                      // Imprimir el ticket
                      final printSuccess = await printerService.printTicket(
                        businessName:
                            provider.profileAccountSelected.name.isNotEmpty
                                ? provider.profileAccountSelected.name
                                : 'PUNTO DE VENTA',
                        products: products,
                        total: provider.ticket.getTotalPrice,
                        paymentMethod: paymentMethod,
                        cashReceived: provider.ticket.valueReceived > 0
                            ? provider.ticket.valueReceived
                            : null,
                        change: provider.ticket.valueReceived >
                                provider.ticket.getTotalPrice
                            ? provider.ticket.valueReceived -
                                provider.ticket.getTotalPrice
                            : null,
                      );

                      // Mostrar resultado
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  printSuccess
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    printSuccess
                                        ? 'Ticket impreso correctamente'
                                        : 'Error al imprimir ticket: ${printerService.lastError ?? "Error desconocido"}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor:
                                printSuccess ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error al procesar impresión: $e',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  } else {
                    // Si no hay impresora, mostrar diálogo de opciones
                    await Future.delayed(const Duration(milliseconds: 800));

                    if (mounted) {
                      await showTicketOptionsDialog(
                        context: context,
                        ticket: provider.ticket,
                        businessName:
                            provider.profileAccountSelected.name.isNotEmpty
                                ? provider.profileAccountSelected.name
                                : 'PUNTO DE VENTA',
                        onComplete: () {
                          // Este callback se ejecuta solo cuando se completa exitosamente
                        },
                      );
                    }
                  }

                  // Guardar el último ticket vendido antes de limpiar
                  await provider.saveLastSoldTicket();
                  
                  // Limpiar ticket después del proceso
                  Future.delayed(const Duration(milliseconds: 500)).then((_) {
                    if (mounted) {
                      setState(() {
                        _showConfirmedPurchase = false;
                      });
                      provider.discartTicket();
                    }
                  });
                } else {
                  // Si el checkbox no está activo, guardar último ticket y limpiar
                  await provider.saveLastSoldTicket();
                  
                  Future.delayed(const Duration(seconds: 2)).then((_) {
                    if (mounted) {
                      setState(() {
                        _showConfirmedPurchase = false;
                      });
                      provider.discartTicket();
                    }
                  });
                }
              },
              icon: Icons.check_circle_outline_rounded,
              text: confirmarText,
            )
            .animate(delay: const Duration(milliseconds: 0))
            .fade(),
      ],
    );
  }

  /// Botones para la vista principal. Solo visible en móvil y cuando el ticket no está visible.
  Widget floatingActionButtonBody({required SellProvider sellProvider}) {
    return Row(
      children: [
        ComponentApp()
            .floatingActionButtonApp(
              onTap: () => showQuickSaleDialog(context, provider: sellProvider),
              icon: Icons.flash_on_rounded,
              buttonColor: Colors.amber,
            )
            .animate(delay: const Duration(milliseconds: 0))
            .fade(),
        const SizedBox(width: 8),
        // button : muestra el botón de cobrar si es móvil y el ticket no está visible
        isMobile(context)
            ? ComponentApp().floatingActionButtonApp(
                onTap: () {
                  sellProvider.setTicketView(true);
                },
                text:
                    'Cobrar ${sellProvider.ticket.getTotalPrice == 0 ? '' : Publications.getFormatoPrecio(value: sellProvider.ticket.getTotalPrice)}',
                buttonColor:
                    sellProvider.ticket.getTotalPrice == 0 ? Colors.grey : null,
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  /// Construye el grid de productos y celdas vacías para llenar toda la vista sin espacios vacíos.
  Widget body({required SellProvider provider}) {
    // widgetss
    Widget itemDefault =
        Card(elevation: 0, color: Colors.grey.withValues(alpha: 0.05));

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        if (constraints.maxWidth < 600) {
          // Ancho mínimo para móviles
          crossAxisCount = 3;
        } else if (constraints.maxWidth < 800) {
          // Ancho para tablets
          crossAxisCount = 4;
        } else if (constraints.maxWidth < 1000) {
          // Ancho para pantallas medianas
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6; // Ancho para pantallas grandes
        }
        // Usar los productos seleccionados del ticket
        final List<ProductCatalogue> list = provider.ticket.listPoduct
            .map((item) => item is ProductCatalogue
                ? item
                : ProductCatalogue.fromMap(item))
            .toList()
            .reversed
            .toList();
        // Calcular cuántas filas caben en la vista
        final double itemHeight = (constraints.maxWidth / crossAxisCount) *
            1.1; // Ajusta el factor según el aspecto de los ítems
        int rowCount = 1;
        int minItemCount = crossAxisCount;
        if (constraints.maxHeight.isFinite &&
            constraints.maxHeight > 0 &&
            itemHeight > 0) {
          rowCount = (constraints.maxHeight / itemHeight).ceil();
          minItemCount = rowCount * crossAxisCount;
        }
        int totalItems = list.length;
        int remainder = totalItems % crossAxisCount;
        int fillCount = remainder == 0 ? 0 : crossAxisCount - remainder;
        int itemCount = totalItems + fillCount;
        // Si la cantidad de ítems no llena la vista, agregar más itemDefault
        if (itemCount < minItemCount) {
          itemCount = minItemCount;
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index < list.length) {
              return ProductoItem(producto: list[index]);
            } else {
              return itemDefault;
            }
          },
      );
      },
    );
  }

  Widget drawerTicket(BuildContext context) {
    // values
    final provider = Provider.of<SellProvider>(context);
    final ticket = provider.ticket;

    // style adaptado a tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Color borderColor = colorScheme.onSurface;
    // Usar un color suave que resalte más el ticket
    Color backgroundColor = colorScheme.primary.withValues(alpha: 0.1);
    final TextStyle textValuesStyle = TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: colorScheme.onSurface);
    final TextStyle textDescrpitionStyle = TextStyle(
        fontFamily: 'RobotoMono', fontSize: 18, color: colorScheme.onSurface);
    final TextStyle textSmallStyle = TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        color: colorScheme.onSurface.withValues(alpha: 0.87));
    final TextStyle textTotalStyle = TextStyle(
        fontFamily: 'RobotoMono',
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: colorScheme.onPrimary);

    Widget dividerLinesWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 5),
      child: Row(children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                size: Size(constraints.maxWidth, 1),
                painter: _DashedLinePainter(
                    color: colorScheme.onSurface.withValues(alpha: 0.2)),
              );
            },
          ),
        ),
      ]),
    );
    return _showConfirmedPurchase
        ? widgetConfirmedPurchase(
                context: context,
                width:
                    isMobile(context) ? MediaQuery.of(context).size.width : 400)
            .animate()
            .scale(
                duration: 600.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1))
        : AnimatedContainer(
            width: isMobile(context) ? MediaQuery.of(context).size.width : 400,
            curve: Curves.fastOutSlowIn,
            duration: const Duration(milliseconds: 300),
            child: Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              elevation: 0,
              color: backgroundColor,
              shape: RoundedRectangleBorder(
                  side: BorderSide(
                      color: borderColor.withValues(alpha: 0.2), width: 0.5),
                  borderRadius: BorderRadius.circular(8.0)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    // view : encabezado del ticket
                    Column(
                      children: [
                        Text(
                            provider.profileAccountSelected.name.isNotEmpty
                                ? provider.profileAccountSelected.name
                                    .toUpperCase()
                                : 'TICKET',
                            style: textDescrpitionStyle.copyWith(
                                fontSize: 22, letterSpacing: 2)),
                        const SizedBox(height: 1),
                        Text('compra', style: textSmallStyle),
                        const SizedBox(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          child: Row(
                            children: [
                              Text('fecha:', style: textSmallStyle),
                              const Spacer(),
                              Text(DateTime.now().toString().substring(0, 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // view : listado de productos del ticket
                    dividerLinesWidget,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      child: Row(
                        children: [
                          Expanded(child: Text('Cant.', style: textSmallStyle)),
                          Expanded(
                              flex: 3,
                              child: Text('Producto', style: textSmallStyle)),
                          Expanded(
                              child: Text('Precio',
                                  style: textSmallStyle,
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    dividerLinesWidget,
                    Flexible(
                      child: _TicketProductListWithIndicator(
                          ticket: ticket, textValuesStyle: textValuesStyle),
                    ),
                    dividerLinesWidget,
                    // view : cantidad total de artículos
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      child: Row(
                        children: [
                          Text('Artículos:', style: textSmallStyle),
                          const Spacer(),
                          Text('${ticket.getProductsQuantity()}',
                              style: textDescrpitionStyle),
                        ],
                      ),
                    ),
                    dividerLinesWidget,
                    const SizedBox(height: 5),
                    // view : vuelto (solo si corresponde)
                    if (ticket.valueReceived > 0 &&
                        ticket.valueReceived >= ticket.getTotalPrice)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, bottom: 5, top: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Spacer(),
                            // button : editar monto recibido y mostrar vuelto
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => dialogSelectedIncomeCash(
                                    initialAmount: ticket.valueReceived),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Vuelto ${Publications.getFormatoPrecio(value: ticket.valueReceived - ticket.getTotalPrice)}',
                                        style: textDescrpitionStyle.copyWith(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // view : total del monto del ticket
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 5, bottom: 4),
                      child: _TotalBounce(
                        total: ticket.getTotalPrice,
                        textStyle: textTotalStyle,
                        color: colorScheme.primary,
                      ),
                    ),

                    // view: Métodos de pago (ChipCheck)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 6, bottom: 0),
                      child: Column(
                        children: [
                          // Texto de métodos de pago
                          Text('Métodos de pago:', style: textSmallStyle),
                          const SizedBox(height: 6),
                          // Chips de métodos de pago
                          paymentMethodChips(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CheckboxListTile para imprimir ticket con contenedor discreto
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Consumer<SellProvider>(
                        builder: (context, sellProvider, __) {
                          return Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: sellProvider.shouldPrintTicket
                                    ? colorScheme.primary.withValues(alpha: 0.3)
                                    : colorScheme.outline
                                        .withValues(alpha: 0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: !sellProvider.shouldPrintTicket
                                  ? colorScheme.primaryContainer
                                      .withValues(alpha: 0.1)
                                  : colorScheme.primaryContainer
                                      .withValues(alpha: 0.7),
                            ),
                            child: CheckboxListTile(
                              dense: true,
                              value: sellProvider.shouldPrintTicket,
                              onChanged: (bool? value) {
                                sellProvider
                                    .setShouldPrintTicket(value ?? false);
                              },
                              title: Text(
                                'Ticket',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: sellProvider.shouldPrintTicket
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              secondary: Icon(
                                sellProvider.shouldPrintTicket
                                    ? Icons.receipt_long
                                    : Icons.receipt_long_outlined,
                                color: sellProvider.shouldPrintTicket
                                    ? colorScheme.primary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        const Spacer(),
                        floatingActionButtonTicket(
                            provider: provider, showClose: isMobile(context)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
  }

  Widget paymentMethodChips() {
    final provider = Provider.of<SellProvider>(context, listen: false);
    return Wrap(
      spacing: 5,
      alignment: WrapAlignment.center,
      runSpacing: 5,
      children: [
        // choiceChip : pago con efectivo
        ChoiceChip(
          label: const Text('Efectivo'),
          selected: provider.ticket.payMode == 'effective',
          onSelected: (bool selected) {
            if (selected) {
              dialogSelectedIncomeCash();
            }
            provider.setPayMode(payMode: selected ? 'effective' : '');
          },
        ),
        // choiceChip : pago con mercado pago
        ChoiceChip(
          label: const Text('Mercado Pago'),
          selected: provider.ticket.payMode == 'mercadopago',
          onSelected: (bool selected) {
            provider.setPayMode(payMode: selected ? 'mercadopago' : '');
          },
        ),
        // choiceChip : pago con tarjeta de credito/debito
        ChoiceChip(
          label: const Text('Tarjeta Deb/Cred'),
          selected: provider.ticket.payMode == 'card',
          onSelected: (bool selected) {
            provider.setPayMode(payMode: selected ? 'card' : '');
          },
        ),
      ],
    );
  }

  Widget widgetConfirmedPurchase(
      {required BuildContext context, double width = 400}) {
    final provider = Provider.of<SellProvider>(context, listen: false);
    final theme = Theme.of(context);
    final ticket = provider.ticket;

    // Obtener información del método de pago
    String paymentMethodText = _getPaymentMethodDisplayText(ticket.payMode);
    IconData paymentIcon = _getPaymentMethodIcon(ticket.payMode);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal con efecto circular
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),

            const SizedBox(height: 24),

            // Título principal
            Text(
              '¡Venta exitosa!',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Subtítulo
            Text(
              'Transacción completada correctamente',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Card con detalles de la venta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Total de la venta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total vendido:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        Publications.getFormatoPrecio(
                            value: ticket.getTotalPrice),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cantidad de artículos
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Artículos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${ticket.getProductsQuantity()}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      // Método de pago
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Método de pago',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                paymentIcon,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                paymentMethodText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Mostrar vuelto si aplica
                  if (ticket.valueReceived > 0 &&
                      ticket.valueReceived > ticket.getTotalPrice) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Vuelto a entregar',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Publications.getFormatoPrecio(
                              value:
                                  ticket.valueReceived - ticket.getTotalPrice,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Información de fecha y hora
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getFormattedDateTime(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Muestra un diálogo para ingresar el monto recibido, con formateo y cálculo de vuelto.
  void dialogSelectedIncomeCash({double? initialAmount}) {
    final provider = Provider.of<SellProvider>(context, listen: false);
    final controller = AppMoneyTextEditingController();

    // Si se proporciona un monto inicial, establecerlo en el controlador
    if (initialAmount != null && initialAmount > 0) {
      controller.updateValue(initialAmount);
    }

    double vuelto = (initialAmount ?? 0) - provider.ticket.getTotalPrice;
    String? errorText; // Variable para controlar el mensaje de error

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final total = provider.ticket.getTotalPrice;
            final theme = Theme.of(context);

            // Lista de chips filtrada: solo mostrar montos que no excedan el valor del ticket
            final availableAmounts = [1000, 2000, 5000, 10000, 20000]
                .where((amount) => amount >= total)
                .toList();

            // Función para confirmar la operación - reutilizable para botón y Enter
            void confirmOperation() {
              if (errorText == null &&
                  vuelto >= 0 &&
                  controller.doubleValue > 0) {
                provider.setReceivedCash(controller.doubleValue);
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              backgroundColor: theme.colorScheme.surface,
              title: const Text('Cobro en efectivo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoneyInputTextField(
                    controller: controller,
                    labelText: 'Monto recibido',
                    errorText: errorText,
                    autofocus: true,
                    style: theme.textTheme.titleLarge,
                    onChanged: (value) {
                      setState(() {
                        vuelto = value - total;
                        // Actualizar mensaje de error basado en el valor ingresado
                        if (value > 0 && value < total) {
                          errorText = 'El monto recibido es insuficiente';
                        } else {
                          errorText = null;
                        }
                      });
                    },
                    onSubmitted: (value) {
                      // Confirmar operación al presionar Enter
                      confirmOperation();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Chips con valores rápidos: solo mostrar montos que no excedan el total
                  if (availableAmounts.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: availableAmounts.map((amount) {
                        return ActionChip(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(
                            Publications.getFormatoPrecio(
                                value: amount.toDouble()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () {
                            controller.updateValue(amount.toDouble());
                            setState(() {
                              vuelto = amount.toDouble() - total;
                              errorText =
                                  null; // Limpiar error al seleccionar chip válido
                            });
                          },
                          backgroundColor: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.4),
                          side: BorderSide(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: theme.textTheme.bodyLarge),
                      Text(Publications.getFormatoPrecio(value: total),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Vuelto:', style: theme.textTheme.bodyLarge),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: vuelto < 0
                              ? theme.colorScheme.error.withValues(alpha: 0.08)
                              : theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: vuelto < 0
                                ? theme.colorScheme.error
                                : theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          child: Text(
                              Publications.getFormatoPrecio(
                                  value: vuelto < 0 ? 0 : vuelto),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 24)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Confirmar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: errorText == null &&
                          vuelto >= 0 &&
                          controller.doubleValue > 0
                      ? confirmOperation
                      : null,
                ),
              ],
            );
          },
        );
      },
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
                Provider.of<SellProvider>(this.context, listen: false)
                    .discartTicket();
                Navigator.of(context).pop();
              },
              child: const Text('Sí'),
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
        backgroundImage: (perfilNegocio.image.isNotEmpty &&
                perfilNegocio.image.contains('https://'))
            ? NetworkImage(perfilNegocio.image)
            : null,
        child: (perfilNegocio.image.isEmpty)
            ? Text(perfilNegocio.name.isNotEmpty ? perfilNegocio.name[0] : '?',
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold))
            : null,
      ),
      title: Text(perfilNegocio.name,
          style:
              const TextStyle(fontSize: 18, overflow: TextOverflow.ellipsis)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green, size: 24)
          : null,
      onTap: onTap,
    );
  }

  /// Muestra un modal con el listado de productos para agregar a seleccionados, con buscador.
  void showModalBottomSheetSelectProducts(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final products = catalogueProvider.products;
    final TextEditingController searchController = TextEditingController();

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
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (context, setState) {
                String search = searchController.text.trim().toLowerCase();
                final filteredProducts = search.isEmpty
                    ? products
                    : products
                        .where((product) =>
                            product.description
                                .toLowerCase()
                                .contains(search) ||
                            product.nameMark.toLowerCase().contains(search) ||
                            product.code.toLowerCase().contains(search))
                        .toList();
                return Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Row(
                      children: [
                        Text('Catálogo',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Buscar entre ${Publications.getFormatAmount(value: products.length)} productos, marca, código',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    if (filteredProducts.isEmpty && search.isEmpty)
                      const Text('No hay productos disponibles'),
                    if (filteredProducts.isEmpty && search.isNotEmpty)
                      const Text('Sin resultados',
                          style: TextStyle(color: Colors.grey)),
                    if (filteredProducts.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return buildProductListItem(
                              product: product,
                              sellProvider: sellProvider,
                              onTap: () {
                                sellProvider
                                    .addProductsticket(product.copyWith());
                                setState(
                                    () {}); // Actualiza la vista del modal al seleccionar
                              },
                              setState: setState,
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Construye el widget de un producto para la lista del modal de selección.
  /// Mejora la UI siguiendo Material 3 y muestra cantidad seleccionada si aplica.
  Widget buildProductListItem(
      {required ProductCatalogue product,
      required SellProvider sellProvider,
      required void Function() onTap,
      required StateSetter setState}) {
    final ticketProducts = sellProvider.ticket.listPoduct
        .map((item) =>
            item is ProductCatalogue ? item : ProductCatalogue.fromMap(item))
        .toList();
    ProductCatalogue? selectedProduct;
    try {
      selectedProduct = ticketProducts
          .firstWhere((p) => p.id == product.id && p.quantity > 0);
    } catch (_) {
      selectedProduct = null;
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 0,
      color: selectedProduct != null
          ? colorScheme.primaryContainer.withValues(alpha: 0.18)
          : colorScheme.surface.withValues(alpha: 0.95),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selectedProduct != null
            ? BorderSide(color: colorScheme.primary, width: 1.2)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        // imagen : imagen del producto cuadrada con un borde redondeado utilizando [cached_network_image]
        leading: ComponentApp().imageProduct(
          imageUrl: product.image,
          size: 50,
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (product.nameMark.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  product.nameMark,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            product.code,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.secondary),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Publications.getFormatoPrecio(value: product.salePrice),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 10),
            if (selectedProduct != null)
              Chip(
                label: Text(
                  selectedProduct.quantity.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        hoverColor: colorScheme.primaryContainer.withValues(alpha: 0.12),
      ),
    );
  }
}

/// Dibuja una línea punteada horizontal para simular el corte de un ticket impreso.
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({this.color = Colors.black38});
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // view : alerta de stock bajo o sin stock
              alertStockText == ''
                  ? Container()
                  : Container(
                      width: double.infinity,
                      color: Colors.red,
                      child: Center(
                          child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Text(alertStockText,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ))),
              // Cambiar Flexible por Expanded para evitar error de argumentos
              Expanded(
                flex: 2,
                child: Center(child: contentImage()),
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
                  // Mostrar el diálogo de edición del producto usando la función reutilizable
                  showProductEditDialog(
                    context,
                    producto: widget.producto,
                    onProductUpdated: () {
                      // Callback opcional para actualizar la UI después de modificar el producto
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
          // view : cantidad de productos seleccionados
          widget.producto.quantity == 1
              ? Container()
              : Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    backgroundColor: Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(widget.producto.quantity.toString(),
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)),
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

    return widget.producto.image != ""
        ? ComponentApp().imageProduct(imageUrl: widget.producto.image)
        : Container(
            color: Colors.grey[100],
            child: Center(
              child: Text(description,
                  style: const TextStyle(
                      fontSize: 24.0,
                      color: Colors.grey,
                      overflow: TextOverflow.clip)),
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
                Text(widget.producto.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                        overflow: TextOverflow.ellipsis),
                    maxLines: 1),
                Text(
                    Publications.getFormatoPrecio(
                        value: widget.producto.salePrice),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.0,
                        color: Colors.black),
                    overflow: TextOverflow.clip,
                    softWrap: false),
              ],
            ),
          );
  }
}

/// Botón personalizado que muestra hasta 2 cuentas asociadas y un icono por defecto, con animación y superposición.
Widget accoutsAssociatedsButton(
    {required BuildContext context,
    required VoidCallback onTap,
    double iconSize = 30}) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final accounts = authProvider.accountsAssociateds;
  // Tomar hasta 2 cuentas para mostrar
  final visibleAccounts = accounts.take(2).toList();
  final double avatarSize =
      iconSize - 3; // Avatares 3dp más chicos que el icono principal
  return InkWell(
    borderRadius: BorderRadius.circular(32),
    onTap: onTap,
    child: SizedBox(
      width: iconSize + (visibleAccounts.length * (avatarSize * 0.85)) + 8,
      height: iconSize + 8,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Tercer avatar: segunda cuenta (si existe)
          if (visibleAccounts.length > 1)
            Positioned(
              left: iconSize * 0.8,
              child: CircleAvatar(
                radius: avatarSize / 1.8,
                backgroundColor: Colors.grey.shade400,
                backgroundImage: (visibleAccounts[1].image.isNotEmpty &&
                        visibleAccounts[1].image.contains('https://'))
                    ? NetworkImage(visibleAccounts[1].image)
                    : null,
                child: (visibleAccounts[1].image.isEmpty)
                    ? Text(
                        visibleAccounts[1].name.isNotEmpty
                            ? visibleAccounts[1].name[0]
                            : '?',
                        style: TextStyle(
                            fontSize: avatarSize * 0.7,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ).animate().slideX(begin: 0.5, end: 0, duration: 400.ms),
            ),
          // Segundo avatar: primer cuenta (si existe)
          if (visibleAccounts.isNotEmpty)
            Positioned(
              left: iconSize * 0.4,
              child: CircleAvatar(
                radius: avatarSize / 1.8,
                backgroundColor: Colors.grey,
                backgroundImage: (visibleAccounts[0].image.isNotEmpty &&
                        visibleAccounts[0].image.contains('https://'))
                    ? NetworkImage(visibleAccounts[0].image)
                    : null,
                child: (visibleAccounts[0].image.isEmpty)
                    ? Text(
                        visibleAccounts[0].name.isNotEmpty
                            ? visibleAccounts[0].name[0]
                            : '?',
                        style: TextStyle(
                            fontSize: avatarSize * 0.7,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold),
                      )
                    : null,
              ).animate().slideX(begin: 0.3, end: 0, duration: 350.ms),
            ),

          // Primer avatar: icono por defecto
          Positioned(
            left: 0,
            child: CircleAvatar(
              radius: iconSize / 2,
              backgroundColor: Colors.blueGrey.shade100,
              child: Icon(Icons.autorenew_rounded,
                  color: Colors.blueGrey, size: iconSize * 0.95),
            ).animate().fade(duration: 300.ms),
          ),
        ],
      ),
    ),
  );
}

/// Widget personalizado que muestra la lista de productos en el ticket con un indicador de "items ocultos" si es necesario.
class _TicketProductListWithIndicator extends StatefulWidget {
  final dynamic ticket;
  final TextStyle textValuesStyle;
  const _TicketProductListWithIndicator(
      {required this.ticket, required this.textValuesStyle});

  @override
  State<_TicketProductListWithIndicator> createState() =>
      _TicketProductListWithIndicatorState();
}

class _TicketProductListWithIndicatorState
    extends State<_TicketProductListWithIndicator> {
  final ScrollController _scrollController = ScrollController();
  bool _showIndicator = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateIndicator);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateIndicator());
  }

  void _updateIndicator() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    final show = max > 0 && offset < max - 8;
    if (_showIndicator != show) {
      setState(() => _showIndicator = show);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateIndicator);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = widget.ticket.listPoduct.map<Widget>((item) {
      final product =
          item is ProductCatalogue ? item : ProductCatalogue.fromMap(item);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Row(
          children: [
            Expanded(
                child:
                    Text('${product.quantity}', style: widget.textValuesStyle)),
            Expanded(
                flex: 3,
                child: Text(product.description,
                    style: widget.textValuesStyle,
                    overflow: TextOverflow.ellipsis)),
            Expanded(
                child: Text(
                    Publications.getFormatoPrecio(
                        value: product.salePrice * product.quantity),
                    style: widget.textValuesStyle,
                    textAlign: TextAlign.right)),
          ],
        ),
      );
    }).toList(growable: false);

    return Stack(
      children: [
        ListView(
          key: const Key('ticket'),
          controller: _scrollController,
          shrinkWrap: false,
          children: items,
        ),
        if (_showIndicator)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 22, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Hay más ítems',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Widget animado que muestra el total con un leve rebote al cambiar el valor.
/// El rebote es visible desde el inicio y cada vez que cambia el total.
class _TotalBounce extends StatefulWidget {
  final double total;
  final TextStyle textStyle;
  final Color color;
  const _TotalBounce({
    required this.total,
    required this.textStyle,
    required this.color,
  });



  @override
  State<_TotalBounce> createState() => _TotalBounceState();
}

class _TotalBounceState extends State<_TotalBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  double? _oldTotal;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _oldTotal = widget.total;
    // Inicia la animación al mostrar el widget por primera vez
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _TotalBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.total != _oldTotal) {
      _controller.forward(from: 0);
      _oldTotal = widget.total;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text('TOTAL', style: widget.textStyle),
            const Spacer(),
            Text(
              Publications.getFormatoPrecio(value: widget.total),
              style: widget.textStyle,
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el diálogo de configuración de impresora
void _showPrinterConfigDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return const PrinterConfigDialog();
    },
  ).then((_) {
    // Actualizar el estado de la impresora cuando se cierra el diálogo
    Provider.of<PrinterProvider>(context, listen: false).refreshStatus();
  });
}

/// Muestra el diálogo del último ticket vendido
void _showLastTicketDialog(BuildContext context, SellProvider provider) {
  if (provider.lastSoldTicket == null) return;
  
  showLastTicketDialog(
    context: context,
    ticket: provider.lastSoldTicket!,
    businessName: provider.profileAccountSelected.name.isNotEmpty
        ? provider.profileAccountSelected.name
        : 'PUNTO DE VENTA',
  );
}

/// Obtiene el texto a mostrar para el método de pago
String _getPaymentMethodDisplayText(String payMode) {
  switch (payMode) {
    case 'effective':
      return 'Efectivo';
    case 'mercadopago':
      return 'Mercado Pago';
    case 'card':
      return 'Tarjeta';
    default:
      return 'Sin especificar';
  }
}

/// Obtiene el icono correspondiente al método de pago
IconData _getPaymentMethodIcon(String payMode) {
  switch (payMode) {
    case 'effective':
      return Icons.payments_rounded;
    case 'mercadopago':
      return Icons.account_balance_wallet_rounded;
    case 'card':
      return Icons.credit_card_rounded;
    default:
      return Icons.help_outline_rounded;
  }
}

/// Obtiene la fecha y hora formateada para mostrar en la confirmación
String _getFormattedDateTime() {
  final now = DateTime.now();
  return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
}
