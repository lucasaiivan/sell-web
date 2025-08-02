import 'dart:ui';

import 'package:sellweb/core/services/thermal_printer_http_service.dart';
import 'package:sellweb/core/widgets/dialogs/configuration/printer_config_dialog_new.dart';
import 'package:sellweb/core/widgets/dialogs/catalogue/add_product_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/catalogue/product_edit_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/sales/cash_flow_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/sales/cash_register_close_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/sales/cash_register_management_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/sales/quick_sale_dialog.dart';
import 'package:sellweb/core/widgets/dialogs/tickets/ticket_options_dialog.dart';
import 'package:sellweb/core/widgets/drawer/drawer_ticket/ticket_drawer_widget.dart';
import 'package:sellweb/core/widgets/ui/product_catalogue_full_screen_view.dart';
import 'package:web/web.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/utils/responsive.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/domain/entities/user.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/widgets/buttons/buttons.dart';
import 'package:sellweb/core/widgets/component/ui.dart';
import '../../core/widgets/dialogs/tickets/last_ticket_dialog.dart';
import '../providers/sell_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/cash_register_provider.dart';
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
    // consumer : escucha los cambios en ventas (SellProvider) y el catalogo (CatalogueProvider)
    return Consumer2<SellProvider, CatalogueProvider>(
      builder: (_, sellProvider, catalogueProvider, __) {
        // --- Si no hay cuenta seleccionada, mostrar la página de bienvenida ---
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
        // --- account demo : Si la cuenta seleccionada es demo y usuario anónimo, cargar productos demo. ---
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Si es cuenta demo y usuario anónimo, cargar productos demo
        if (sellProvider.profileAccountSelected.id == 'demo' &&
            authProvider.user?.isAnonymous == true &&
            catalogueProvider.products.isEmpty) {
          final demoProducts =
              authProvider.getUserAccountsUseCase.getDemoProducts();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            catalogueProvider.loadDemoProducts(demoProducts);
          });
        }

        // inicialiar [initializeFromPersistence]

        // --- si ahi cuenta seleccionada, mostrar la página de venta ---
        return Scaffold(
          appBar: appbar(buildContext: context, provider: sellProvider),
          drawer: drawer,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Flexible(
                    child: Stack(
                      children: [
                        // -----------------------------
                        /// scan bar (KeyboardListener) se utiliza para detectar y responder a eventos del Escaner de codigo de barra
                        // -----------------------------
                        /// body : cuerpo de la página de venta
                        /// ----------------------------
                        KeyboardListener(
                          focusNode: _focusNode,
                          autofocus: true,
                          onKeyEvent: _onKey,
                          child: body(provider: sellProvider),
                        ),
                        // floatingActionButtonBody : boton flotante para agregar productos al ticket
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: floatingActionButtonBody(
                              sellProvider: sellProvider),
                        ),
                      ],
                    ),
                  ),
                  // si es mobile, no mostrar el drawer o si no se seleccionó ningun producto
                  if (!isMobile(context) &&
                          sellProvider.ticket.getProductsQuantity() != 0 ||
                      (isMobile(context) && sellProvider.ticketView))
                    // drawerTicket : información del ticket
                    TicketDrawerWidget(
                      showConfirmedPurchase:
                          _showConfirmedPurchase, // para mostrar el mensaje de compra confirmada
                      onEditCashAmount: () =>
                          dialogSelectedIncomeCash(), // para editar el monto de efectivo recibido
                      onConfirmSale: () =>
                          _confirmSale(sellProvider), // para confirmar la venta
                      onCloseTicket: () => sellProvider
                          .setTicketView(false), // para cerrar el ticket
                    ),
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
      // - Si se encuentra el producto en el catálogo, agregarlo al ticket -
      homeProvider.addProductsticket(product.copyWith());
    } else {
      // Si no se encuentra el producto en el catálogo, buscar en la base pública
      final publicProduct =
          await catalogueProvider.getPublicProductByCode(code);

      if (publicProduct != null) {
        // Si se encuentra un producto público, mostrar el diálogo para agregarlo al ticket
        final productCatalogue = publicProduct.convertProductCatalogue();
        if (mounted) {
          // ignore: use_build_context_synchronously
          showAddProductDialog(context, product: productCatalogue);
        }
      } else {
        // Si no se encuentra el producto, mostrar un diálogo de [producto no encontrado]
        if (mounted) {
          // ignore: use_build_context_synchronously
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
                AppOutlinedButton(
                  text: 'Cancelar',
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 12),
                // button : Agregar producto
                AppButton(
                  text: 'Crear producto',
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                    showAddProductDialog(context,
                        isNew: true,
                        product: ProductCatalogue(id: code, code: code));
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
                      // Remover la cuenta seleccionada y limpiar datos
                      await sellProvider.removeSelectedAccount();
                      // Cerrar el modal
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
    // provider
    final catalogueProvider = Provider.of<CatalogueProvider>(buildContext);
    // values
    final bool isLoading = catalogueProvider.isLoading;
    final bool isEmpty = !isLoading && catalogueProvider.products.isEmpty;
    String textHintSearchButton = isLoading
        ? 'Cargando...'
        : isEmpty
            ? isMobile(buildContext)
                ? 'Sin Productos'
                : 'No hay productos disponibles'
            : isMobile(buildContext)
                ? 'Buscar'
                : 'Buscar productos';

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
              // avatar : avatar de usuario y botón de abrir drawer
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: UserAvatar(
                    imageUrl: provider.profileAccountSelected.image,
                    text: provider.profileAccountSelected.name,
                    radius: 18,
                  ),
                ),
              ),
              // button : busqueda de productos
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 8.0),
                child: SearchButton(
                  height: 40,
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
                  label: textHintSearchButton,
                  color: Theme.of(buildContext).colorScheme.primaryContainer,
                  textColor:
                      Theme.of(buildContext).colorScheme.onPrimaryContainer,
                  iconColor:
                      Theme.of(buildContext).colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              // view : botones de la barra de acciones
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
                        onPressed: () => _showPrinterConfigDialog(buildContext),
                        backgroundColor: isConnected
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.07),
                        iconColor: isConnected
                            ? Colors.green.shade700
                            : Colors.orange.shade500,
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
                        backgroundColor: hasLastTicket
                            ? Theme.of(buildContext)
                                .colorScheme
                                .primaryContainer
                                .withValues(alpha: 0.4)
                            : Colors.grey.withValues(alpha: 0.15),
                        iconColor: hasLastTicket
                            ? Theme.of(buildContext).colorScheme.primary
                            : Colors.grey.shade400,
                      );
                    },
                  ),

                  // button : administrar caja
                  CashRegisterStatusWidget(),

                  // Botón de descartar ticket (existente) usando [AppBarButtonCircle]
                  (provider.ticket.getProductsQuantity() > 0)
                      ? AppBarButtonCircle(
                          icon: Icons.close,
                          text:
                              isMobile(buildContext) ? '' : 'Descartar ticket',
                          tooltip: 'Descartar ticket',
                          onPressed: discartTicketAlertDialg,
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          iconColor: Colors.red.shade700,
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
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // view : logo y título de encabezado
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
                  // Controles de tema reutilizables
                  ThemeControlButtons(
                    spacing: 4,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            // listitle : perfil de negocio, nombre de la cuenta seleccionada y avatar
            ListTile(
              leading: UserAvatar(
                  imageUrl: sellProvider.profileAccountSelected.image,
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
                      child: AppButton(
                        text: 'Descargar App',
                        onPressed: () {
                          // Abre la URL de descarga de la app
                          html.window.open(
                            'https://play.google.com/store/apps/details?id=com.sellweb.app',
                            '_blank',
                          );
                        },
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lógica para confirmar la venta y procesar el ticket
  Future<void> _confirmSale(SellProvider provider) async {
    setState(() {
      _showConfirmedPurchase =
          true; // para mostrar el mensaje de compra confirmada
    });

    // Si el checkbox está activo, procesar la impresión/generación de tickets
    if (provider.shouldPrintTicket) {
      await _processSaveAndPrintTicket(provider);
    } else {
      await _processSimpleSaveSale(provider);
    }
  }

  /// Procesa la venta con impresión de ticket
  Future<void> _processSaveAndPrintTicket(SellProvider provider) async {
    // Obtener el provider de caja registradora
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);

    // Si hay una caja activa, registrar la venta
    if (cashRegisterProvider.hasActiveCashRegister) {
      final activeCashRegister =
          cashRegisterProvider.currentActiveCashRegister!;
      provider.ticket.cashRegisterName = activeCashRegister.description;
      provider.ticket.cashRegisterId = activeCashRegister.id;

      await cashRegisterProvider.registerSale(
        accountId: provider.profileAccountSelected.id,
        saleAmount: provider.ticket.getTotalPrice,
        discountAmount: provider.ticket.discount,
        itemCount: provider.ticket.getProductsQuantity(),
      );
    }

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
        final products = provider.ticket.products.map((item) {
          return {
            'quantity': item.quantity.toString(),
            'description': item.description,
            'price': item.salePrice,
          };
        }).toList();

        // Imprimir el ticket
        final printSuccess = await printerService.printTicket(
          businessName: provider.profileAccountSelected.name.isNotEmpty
              ? provider.profileAccountSelected.name
              : 'PUNTO DE VENTA',
          products: products,
          total: provider.ticket.getTotalPrice,
          paymentMethod: paymentMethod,
          cashReceived: provider.ticket.valueReceived > 0
              ? provider.ticket.valueReceived
              : null,
          change: provider.ticket.valueReceived > provider.ticket.getTotalPrice
              ? provider.ticket.valueReceived - provider.ticket.getTotalPrice
              : null,
        );

        // Mostrar resultado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    printSuccess ? Icons.check_circle : Icons.error,
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
              backgroundColor: printSuccess ? Colors.green : Colors.red,
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
          businessName: provider.profileAccountSelected.name.isNotEmpty
              ? provider.profileAccountSelected.name
              : 'PUNTO DE VENTA',
          onComplete: () {
            // Este callback se ejecuta solo cuando se completa exitosamente
          },
        );
      }
    }

    // ===== GUARDAR EN HISTORIAL DE TRANSACCIONES (SIEMPRE) =====

    // Obtener información del usuario para asignar como vendedor
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? 'unknown@example.com';
    final userName = authProvider.user?.displayName ?? 'Vendedor';

    // GUARDAR TRANSACCIÓN EN HISTORIAL SIEMPRE (con o sin caja activa)
    await cashRegisterProvider.saveTicketToTransactionHistory(
      accountId: provider.profileAccountSelected.id,
      ticket: provider.ticket,
      sellerName: userName,
      sellerId: userEmail,
    );

    // ===== INCREMENTAR VENTAS DE PRODUCTOS EN EL CATÁLOGO =====
    await _updateProductSalesAndStock(provider);

    // Imprimir resultado del guardado
    await _finalizeSale(provider);
  }

  /// === Procesa la venta simple sin impresión de ticket ===
  Future<void> _processSimpleSaveSale(SellProvider provider) async {
    // Obtener el provider de caja registradora
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);

    // Si hay una caja activa, registrar la venta en la caja
    if (cashRegisterProvider.hasActiveCashRegister) {
      // Obtener la caja activa y asignar los datos al ticket
      final activeCashRegister =
          cashRegisterProvider.currentActiveCashRegister!;
      provider.ticket.cashRegisterName = activeCashRegister.description;
      provider.ticket.cashRegisterId = activeCashRegister.id;
      // Registrar la venta en la caja
      await cashRegisterProvider.registerSale(
        accountId: provider.profileAccountSelected.id,
        saleAmount: provider.ticket.getTotalPrice,
        discountAmount: provider.ticket.discount,
        itemCount: provider.ticket.getProductsQuantity(),
      );
    }

    // ===== GUARDAR EN HISTORIAL DE TRANSACCIONES (SIEMPRE) =====

    // Obtener información del usuario para asignar como vendedor
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? 'unknown@example.com';
    final userName = authProvider.user?.displayName ?? 'Vendedor';

    // GUARDAR TRANSACCIÓN EN HISTORIAL SIEMPRE (con o sin caja activa)
    await cashRegisterProvider.saveTicketToTransactionHistory(
      accountId: provider.profileAccountSelected.id,
      ticket: provider.ticket,
      sellerName: userName,
      sellerId: userEmail,
    );

    // ===== INCREMENTAR VENTAS DE PRODUCTOS EN EL CATÁLOGO =====
    await _updateProductSalesAndStock(provider);

    // Imprimir resultado del guardado
    await _finalizeSale(provider);
  }

  /// Finaliza la venta guardando el último ticket y limpiando
  Future<void> _finalizeSale(SellProvider provider) async {
    // Guardar el último ticket vendido
    await provider.saveLastSoldTicket();

    // Limpiar ticket después del proceso
    Future.delayed(const Duration(milliseconds: 300)).then((_) {
      if (mounted) {
        setState(() {
          _showConfirmedPurchase = false;
        });
        provider.discartTicket();
      }
    });
  }

  /// Actualiza las estadísticas de ventas y stock de los productos en el catálogo
  ///
  /// Este método se ejecuta después de confirmar una venta para:
  /// 1. Incrementar el contador de ventas de cada producto
  /// 2. Decrementar el stock si el producto tiene habilitado el control de stock
  Future<void> _updateProductSalesAndStock(SellProvider provider) async {
    try {
      // Obtener el provider del catálogo
      final catalogueProvider =
          Provider.of<CatalogueProvider>(context, listen: false);
      final accountId = provider.profileAccountSelected.id;

      // Procesar cada producto del ticket
      for (final product in provider.ticket.products) {
        if (product.code.isEmpty) {
          // Si el producto no tiene código, saltar (productos de venta rápida)
          continue;
        }

        try {
          // Incrementar ventas del producto en el catálogo
          await catalogueProvider.incrementProductSales(
            accountId,
            product.id,
            quantity: product.quantity,
          );

          // Si el producto tiene control de stock habilitado, decrementar stock
          if (product.stock && product.quantityStock > 0) {
            await catalogueProvider.decrementProductStock(
              accountId,
              product.id,
              product.quantity,
            );
          }
        } catch (productError) {
          // Si falla la actualización de un producto específico, continuar con los demás
        }
      }
    } catch (e) {
      // Registrar el error pero no fallar la venta

      // Opcionalmente mostrar una notificación al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Venta registrada correctamente. Hay un problema menor con la actualización de estadísticas.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  /// Botones para la vista principal. Solo visible en móvil y cuando el ticket no está visible.
  Widget floatingActionButtonBody({required SellProvider sellProvider}) {
    return Row(
      children: [
        AppFloatingActionButton(
          onTap: () => showQuickSaleDialog(context, provider: sellProvider),
          icon: Icons.flash_on_rounded,
          buttonColor: Colors.amber,
        ).animate(delay: const Duration(milliseconds: 0)).fade(),
        const SizedBox(width: 8),
        // button : muestra el botón de cobrar si es móvil y el ticket no está visible
        isMobile(context)
            ? AppFloatingActionButton(
                onTap: () {
                  if (sellProvider.ticket.getTotalPrice == 0) {
                    return;
                  }
                  sellProvider.setTicketView(true);
                },
                text:
                    'Cobrar ${sellProvider.ticket.getTotalPrice == 0 ? '' : Publications.getFormatoPrecio(value: sellProvider.ticket.getTotalPrice)}',
                buttonColor:
                    sellProvider.ticket.getTotalPrice == 0 ? Colors.grey : null,
                extended: true,
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  /// Construye el grid de productos y celdas vacías para llenar toda la vista sin espacios vacíos.
  Widget body({required SellProvider provider}) {
    // widgets
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Color adaptativo para items default que se ve bien en tema claro y oscuro
    // Usa surface con una opacidad muy baja para crear un contraste sutil
    Widget itemDefault = Card(
      elevation: 0,
      color: colorScheme.onSurface.withValues(alpha: 0.07),
    );

    return Consumer<CatalogueProvider>(
      builder: (context, catalogueProvider, child) {
        return LayoutBuilder(builder: (context, constraints) {
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
          final List<ProductCatalogue> list =
              provider.ticket.products.toList().reversed.toList();
          // Calcular cuántas filas caben en la vista
          final double itemHeight = (constraints.maxWidth / crossAxisCount) *
              1.1; // Ajusta el factor según el aspecto de los ítems
          int rowCount = 1;
          int minItemCount = crossAxisCount;
          // Si la altura del contenedor es finita y mayor a 0, calcular el número de filas
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

          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [_buildFavoriteProductsRow(provider)],
                  ),
                ),
              ];
            },
            body: GridView.builder(
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
            ),
          );
        });
      },
    );
  }

  /// Construye la lista horizontal de productos favoritos con estilo de historias de Instagram
  Widget _buildFavoriteProductsRow(SellProvider provider) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    // Usar el método del provider para obtener productos más vendidos
    final displayProducts = catalogueProvider.getTopFilterProducts();

    // Si no hay productos con ventas, no mostrar nada
    if (displayProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ScrollConfiguration(
            behavior: const MaterialScrollBehavior().copyWith(
              scrollbars: true,
              dragDevices: {
                PointerDeviceKind.mouse,
                PointerDeviceKind.touch,
                PointerDeviceKind.stylus,
                PointerDeviceKind.unknown,
              },
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: displayProducts.length,
              itemBuilder: (context, index) {
                final product = displayProducts[index];
                final isInTicket =
                    provider.ticket.products.any((p) => p.id == product.id);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AvatarCircleProduct(
                    product: product,
                    isSelected: isInTicket,
                    onTap: () {
                      // Agregar producto al ticket al hacer tap
                      provider.addProductsticket(product.copyWith());
                    },
                  ),
                );
              },
            )));
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

  /// Muestra una vista de pantalla completa con el listado de productos para agregar a seleccionados, con buscador dinámico.
  void showModalBottomSheetSelectProducts(BuildContext context) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final products = catalogueProvider.products;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductCatalogueFullScreenView(
                products: products, sellProvider: sellProvider),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Construye el widget de un producto para la lista del modal de selección.
  /// Mejora la UI siguiendo Material 3 y muestra cantidad seleccionada si aplica.
  Widget buildProductListItem(
      {required ProductCatalogue product,
      required SellProvider sellProvider,
      required void Function() onTap,
      required StateSetter setState}) {
    //
    final ticketProducts = sellProvider.ticket.products;
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
          leading: ProductImage(
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          hoverColor: colorScheme.primaryContainer.withValues(alpha: 0.12),
        ));
  }
}

class ProductoItem extends StatefulWidget {
  final ProductCatalogue producto;

  const ProductoItem({super.key, required this.producto});

  @override
  State<ProductoItem> createState() => _ProductoItemState();
}

class _ProductoItemState extends State<ProductoItem> {
  
  // Identifica si es un producto de venta rápida
  bool get _isQuickSaleProduct {
    return widget.producto.id.isEmpty || 
           widget.producto.id.startsWith('quick_') ||
           widget.producto.description.isEmpty;
  }

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
          // Si es venta rápida, mostrar solo precio centrado
          _isQuickSaleProduct ? _buildQuickSaleLayout() : _buildNormalLayout(alertStockText),
          // view : selección del producto
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

  /// Layout para productos de venta rápida - solo precio centrado
  Widget _buildQuickSaleLayout() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration( 
        color: Colors.grey.shade200.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            Publications.getFormatoPrecio(value: widget.producto.salePrice),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22, // Precio más grande
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Layout normal para productos con descripción
  Widget _buildNormalLayout(String alertStockText) {
    return Column(
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
        // image : imagen del producto que ocupa parte de la tarjeta
        Expanded(
          flex: 2,
          child: ProductImage(
            imageUrl: widget.producto.image,
            fit: BoxFit.cover,
          ),
        ),
        // view : información del producto
        contentInfo(),
      ],
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

/// --- Widget --- que muestra un botón para ver el estado de la caja registradora.
/// Al tocarlo, abre un diálogo con los detalles.
class CashRegisterStatusWidget extends StatefulWidget {
  const CashRegisterStatusWidget({super.key});

  @override
  State<CashRegisterStatusWidget> createState() =>
      _CashRegisterStatusWidgetState();
}

class _CashRegisterStatusWidgetState extends State<CashRegisterStatusWidget> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales con persistencia sin esperar al build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCashRegister();
    });
  }

  // - Inicializa la caja registradora desde la persistencia -
  Future<void> _initializeCashRegister() async {
    // Obtener el proveedor de caja registradora y la cuenta seleccionada
    final sellProvider = context.read<SellProvider>();
    final accountId = sellProvider.profileAccountSelected.id;

    if (accountId.isNotEmpty) {
      // Inicializar la caja registradora desde la persistencia
      await context
          .read<CashRegisterProvider>()
          .initializeFromPersistence(accountId);
    }

    // Marcar como completada la inicialización
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  // - Muestra el popup menu con opciones de caja registradora -
  void _showStatusDialog(BuildContext context) {
    // - obtenemos los proveedores necesarios para el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Obtener el balance esperado de la caja activa
    final balance = cashRegisterProvider.hasActiveCashRegister
        ? cashRegisterProvider.currentActiveCashRegister?.getExpectedBalance ??
            0.0
        : 0.0;

    // Mostrar popup menu
    showMenu<String>(
      context: context,
      menuPadding: const EdgeInsets.all(0),
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200, // Posición desde la derecha
        kToolbarHeight + 20, // Debajo del AppBar
        20,
        0,
      ),
      items: [
        // item : Titular con balance total (cliqueable para ir al administrador)
        PopupMenuItem<String>(
          value: 'manage',
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Balance Total',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Publications.getFormatoPrecio(value: balance),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const Divider(height: 16),
            ],
          ),
        ),
        // Opción de ingreso (solo si hay caja activa)
        if (cashRegisterProvider.hasActiveCashRegister)
          PopupMenuItem<String>(
            value: 'income',
            child: Row(
              children: [
                Icon(Icons.arrow_downward_sharp,
                    size: 20, color: Colors.green.shade600),
                const SizedBox(width: 12),
                const Text('Ingreso'),
              ],
            ),
          ),
        // Opción de egreso (solo si hay caja activa)
        if (cashRegisterProvider.hasActiveCashRegister)
          PopupMenuItem<String>(
            value: 'expense',
            child: Row(
              children: [
                Icon(Icons.arrow_outward_rounded,
                    size: 20, color: Colors.red.shade600),
                const SizedBox(width: 12),
                const Text('Egreso'),
              ],
            ),
          ),
        // Opción para cerrar caja (solo si hay caja activa)
        if (cashRegisterProvider.hasActiveCashRegister)
          PopupMenuItem<String>(
            value: 'close',
            child: Row(
              children: [
                Icon(Icons.exit_to_app, size: 20),
                const SizedBox(width: 12),
                const Text('Cerrar caja'),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'manage':
            // Mostrar el diálogo completo de administración
            showDialog(
              context: context,
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<CashRegisterProvider>.value(
                      value: cashRegisterProvider),
                  ChangeNotifierProvider<SellProvider>.value(
                      value: sellProvider),
                  ChangeNotifierProvider<AuthProvider>.value(
                      value: authProvider),
                ],
                child: const CashRegisterManagementDialog(),
              ),
            );
            break;
          case 'income':
            // Reutilizar CashFlowDialog para ingresos
            _showCashFlowDialog(context, true, cashRegisterProvider,
                sellProvider, authProvider);
            break;
          case 'expense':
            // Reutilizar CashFlowDialog para egresos
            _showCashFlowDialog(context, false, cashRegisterProvider,
                sellProvider, authProvider);
            break;
          case 'close':
            // Mostrar confirmación de cierre
            _showCloseCashRegisterDialog(
                context, cashRegisterProvider, sellProvider);
            break;
        }
      }
    });
  }

  // - Reutiliza CashFlowDialog para mostrar diálogo de ingresos/egresos -
  void _showCashFlowDialog(
      BuildContext context,
      bool isInflow,
      CashRegisterProvider cashRegisterProvider,
      SellProvider sellProvider,
      AuthProvider authProvider) {
    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: CashFlowDialog(
          isInflow: isInflow,
          cashRegisterId: cashRegister.id,
          accountId: sellProvider.profileAccountSelected.id,
          userId: authProvider.user?.email ?? '',
        ),
      ),
    );
  }

  // - Reutiliza CashRegisterCloseDialog para mostrar diálogo de cierre -
  void _showCloseCashRegisterDialog(BuildContext context,
      CashRegisterProvider cashRegisterProvider, SellProvider sellProvider) {
    final currentCashRegister = cashRegisterProvider.currentActiveCashRegister;
    if (currentCashRegister == null) return;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
        ],
        child: CashRegisterCloseDialog(cashRegister: currentCashRegister),
      ),
    );
  }

  // - Muestra el diálogo completo de administración de caja registradora -
  void _showCashRegisterManagementDialog(BuildContext context) {
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SellProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SellProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: const CashRegisterManagementDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // consumer : obtiene el estado de la caja registradora
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        final bool isActive = provider.hasActiveCashRegister;

        // button : boton con el estado de la caja registradora
        return AppBarButtonCircle(
          isLoading: _isInitializing,
          icon: Icons.point_of_sale_outlined,
          tooltip: isActive ? 'Caja abierta' : 'Caja cerrada',
          onPressed: () {
            // Si no hay caja activa, abrir directamente el administrador de caja
            if (!isActive) {
              _showCashRegisterManagementDialog(context);
            } else {
              // Si hay caja activa, mostrar el popup menu
              _showStatusDialog(context);
            }
          },
          backgroundColor: isActive
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          iconColor: isActive ? Colors.green.shade700 : Colors.grey.shade600,
          text: isMobile(context)
              ? null
              : isActive
                  ? '${provider.currentActiveCashRegister?.description}'
                  : 'Iniciar caja',
        );
      },
    );
  }
}
