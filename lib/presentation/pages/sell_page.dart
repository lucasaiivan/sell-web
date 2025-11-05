import 'dart:ui';

import 'package:sellweb/core/core.dart';
import 'package:sellweb/presentation/widgets/dialogs/views/sales/cash_flow_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/views/sales/cash_register_close_dialog.dart';
import 'package:sellweb/presentation/widgets/dialogs/views/sales/cash_register_management_dialog.dart';
import 'package:web/web.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import 'package:sellweb/domain/entities/user.dart';
import '../providers/sell_provider.dart';
import '../providers/catalogue_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/printer_provider.dart';
import '../providers/cash_register_provider.dart';
import '../widgets/navigation/drawer.dart';

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

        // --- pantalla principal de venta ---
        return Scaffold(
          appBar: appbar(buildContext: context, provider: sellProvider),
          drawer: const AppDrawer(),
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
                      onCloseTicket: _showConfirmedPurchase
                          ? _onConfirmationComplete // Callback especial cuando está en modo confirmación
                          : () => sellProvider.setTicketView(
                              false), // para cerrar el ticket normalmente
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

    if (product != null &&
        product.id.isNotEmpty &&
        product.description.isNotEmpty) {
      // - Si se encuentra el producto en el catálogo con datos válidos, agregarlo al ticket -
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
                ButtonApp.outlined(
                  text: 'Cancelar',
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 12),
                // button : Agregar producto
                ButtonApp.primary(
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
                            : null,
                        colorAccent: isConnected ? Colors.green.shade700 : null,
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
                          backgroundColor: Theme.of(buildContext)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4),
                          colorAccent:
                              Theme.of(buildContext).colorScheme.primary);
                    },
                  ),

                  // button : administrar caja
                  CashRegisterStatusWidget(),
 
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

  /// Lógica para confirmar la venta y procesar el ticket
  Future<void> _confirmSale(SellProvider provider) async {
    setState(() {
      _showConfirmedPurchase =
          true; // para mostrar el mensaje de compra confirmada
    });

    try {
      // Usar el método unificado del provider
      await provider.processSale(context);
    } catch (e) {
      // El error ya se maneja en el provider, solo necesitamos resetear el estado
      if (mounted) {
        setState(() {
          _showConfirmedPurchase = false;
        });
      }
    }
  }

  /// Callback que se ejecuta cuando la animación de confirmación se completa
  void _onConfirmationComplete() {
    if (mounted) {
      setState(() {
        _showConfirmedPurchase = false;
      });
      final provider = Provider.of<SellProvider>(context, listen: false);
      provider.discartTicket();
      provider.setTicketView(false);
    }
  }

  /// Botones para la vista principal. Solo visible en móvil y cuando el ticket no está visible.
  Widget floatingActionButtonBody({required SellProvider sellProvider}) {
    return Row(
      children: [
        // button : descartar ticket si es existente y tiene productos
        if (sellProvider.ticket.getProductsQuantity() > 0)
          ButtonApp.fab(
            heroTag: "discard_ticket_fab", // Hero tag único
            onPressed: () => discartTicketAlertDialg(),
            icon: Icons.close_rounded,
            backgroundColor: Colors.grey,
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
        const SizedBox(width: 8),
        // button : muestra el botón de venta rápida
        ButtonApp.fab(
          heroTag: "quick_sale_fab", // Hero tag único
          onPressed: () => showQuickSaleDialog(context, provider: sellProvider),
          icon: Icons.flash_on_rounded,
          backgroundColor: Colors.amber,
        ).animate(delay: const Duration(milliseconds: 0)).fade(),
        const SizedBox(width: 8),
        // button : muestra el botón de cobrar si es móvil y el ticket no está visible
        isMobile(context)
            ? ButtonApp.fab(
                heroTag: "charge_fab", // Hero tag único
                onPressed: () {
                  if (sellProvider.ticket.getTotalPrice == 0) {
                    return;
                  }
                  sellProvider.setTicketView(true);
                },
                text:
                    'Cobrar ${sellProvider.ticket.getTotalPrice == 0 ? '' : CurrencyFormatter.formatPrice(value: sellProvider.ticket.getTotalPrice)}',
                backgroundColor:
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
                            CurrencyFormatter.formatPrice(
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
                      Text(CurrencyFormatter.formatPrice(value: total),
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
                              CurrencyFormatter.formatPrice(
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
    required AccountProfile perfilNegocio,
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
                CurrencyFormatter.formatPrice(value: product.salePrice),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBackgroundColor = isDark 
        ? theme.colorScheme.surfaceContainerHighest 
        : Colors.white;
    
    final String alertStockText = widget.producto.stock
        ? (widget.producto.quantityStock >= 0
            ? widget.producto.quantityStock <= widget.producto.alertStock
                ? 'Stock bajo'
                : ''
            : 'Sin stock')
        : '';

    // aparición animada
    return Card(
      color: cardBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Si es venta rápida, mostrar solo precio centrado
          _isQuickSaleProduct
              ? _buildQuickSaleLayout()
              : _buildNormalLayout(alertStockText),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark 
        ? theme.colorScheme.onSurface 
        : Colors.black87;
    final overlayColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
        : Colors.grey.shade200.withValues(alpha: 0.2);
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: overlayColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            CurrencyFormatter.formatPrice(value: widget.producto.salePrice),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22, // Precio más grande
              color: textColor,
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
        // image : imagen del producto que ocupa parte de la tarjeta con alerta de stock superpuesta
        Expanded(
          flex: 2,
          child: Stack(
            children: [
              ProductImage(
                borderRadius: 12,
                imageUrl: widget.producto.image,
                fit: BoxFit.cover,
              ),
              // view : alerta de stock bajo o sin stock
              if (alertStockText.isNotEmpty)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        alertStockText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // view : información del producto
        contentInfo(),
      ],
    );
  }

  Widget contentInfo() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final descriptionColor = isDark 
        ? theme.colorScheme.onSurfaceVariant 
        : Colors.grey;
    final priceColor = isDark 
        ? theme.colorScheme.onSurface 
        : Colors.black;
    
    return widget.producto.description == ''
        ? Container()
        : Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(widget.producto.description,
                    style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: descriptionColor,
                        overflow: TextOverflow.ellipsis),
                    maxLines: 1),
                Text(
                    CurrencyFormatter.formatPrice(
                        value: widget.producto.salePrice),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17.0,
                        color: priceColor),
                    overflow: TextOverflow.clip,
                    softWrap: false),
              ],
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
  if (provider.lastSoldTicket == null) return; // No hay ticket para mostrar
  final ticket = provider.lastSoldTicket!;

  showLastTicketDialog(
      context: context,
      ticket: ticket,
      title: 'Último ticket',
      businessName: provider.profileAccountSelected.name.isNotEmpty
          ? provider.profileAccountSelected.name
          : 'PUNTO DE VENTA',
      onTicketAnnulled: () async {
        await provider.annullLastSoldTicket(context: context, ticket: ticket);
      });
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
                CurrencyFormatter.formatPrice(value: balance),
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
            // Mostrar el diálogo completo de administración usando el método estático
            CashRegisterManagementDialog.showAdaptive(context);
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
    // Usar el método adaptativo que detecta automáticamente el tipo de dispositivo
    CashRegisterManagementDialog.showAdaptive(context);
  }

  @override
  Widget build(BuildContext context) {
    // consumer : obtiene el estado de la caja registradora
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        final bool isActive = provider.hasActiveCashRegister;
        final int salesCount = provider.currentActiveCashRegister?.sales ?? 0;

        // button : boton con el estado de la caja registradora
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AppBarButtonCircle(
              isLoading: _isInitializing,
              icon: Icons.point_of_sale_outlined,
              tooltip: isActive ? 'Caja abierta' : 'Abrir caja',
              onPressed: () {
                // Si no hay caja activa, abrir directamente el administrador de caja
                if (!isActive) {
                  _showCashRegisterManagementDialog(context);
                } else {
                  // Si hay caja activa, mostrar el diálogo de estado
                  isMobile(context)
                      ? _showStatusDialog(context)
                      : _showCashRegisterManagementDialog(context);
                }
              },
              backgroundColor:
                  isActive ? Colors.green.withValues(alpha: 0.1) : null,
              colorAccent: isActive ? Colors.green.shade700 : null,
              text: isMobile(context)
                  ? null
                  : (isActive ? 'Caja abierta' : 'Abrir caja'),
            ),
            // contador : burbuja circular roja con contador de ventas
            if (isActive && salesCount > 0)
              Positioned(
                right: -1,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: salesCount > 99 ? 6 : 4,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      salesCount > 999 ? '999+' : salesCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                        letterSpacing: 0.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
