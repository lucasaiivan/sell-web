import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/core/constants/payment_methods.dart';
import 'package:sellweb/core/core.dart';
import 'package:sellweb/features/cash_register/presentation/dialogs/cash_flow_dialog.dart';
import 'package:sellweb/features/sales/presentation/dialogs/cash_register_close_dialog.dart';
import 'package:sellweb/features/sales/presentation/dialogs/cash_register_management_dialog.dart';
import 'package:web/web.dart' as html;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sellweb/features/catalogue/domain/entities/product_catalogue.dart';
import 'package:sellweb/features/auth/domain/entities/account_profile.dart';
import 'package:sellweb/features/auth/domain/entities/admin_profile.dart';
import 'package:sellweb/features/sales/presentation/providers/sales_provider.dart';
import 'package:sellweb/features/catalogue/presentation/providers/catalogue_provider.dart';
import 'package:sellweb/features/auth/presentation/providers/auth_provider.dart';
import 'package:sellweb/features/sales/presentation/providers/printer_provider.dart';
import 'package:sellweb/features/cash_register/presentation/providers/cash_register_provider.dart';
import 'package:sellweb/features/home/presentation/providers/home_provider.dart';
import 'package:sellweb/core/presentation/widgets/navigation/drawer.dart'; 
import 'package:sellweb/features/sales/presentation/widgets/product_item.dart';
import 'package:sellweb/core/services/demo_account/demo_account_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  final FocusNode _focusNode = FocusNode();
  bool _showConfirmedPurchase = false;
  bool _isListenerActive = false; // Control del estado del listener

  bool _isDialogOpen = false;
  BuildContext? _manualDialogContext;
  late final _ScannerInputController _scannerInputController;
  int? _lastHomePageIndex;
  bool _skipExitDialogOnce = false;
  
  // AudioPlayer para el sonido de escaneo
  final AudioPlayer _scanAudioPlayer = AudioPlayer();

  // GlobalKeys para el showcase
  final GlobalKey _quickSaleKey = GlobalKey();
  final GlobalKey _cashRegisterKey = GlobalKey();
  final GlobalKey _lastTicketKey = GlobalKey();
  final GlobalKey _printerKey = GlobalKey();
  final GlobalKey _searchProductKey = GlobalKey();
  final GlobalKey _favoritesKey = GlobalKey();
  
  // Showcase Parte 2 (Cobrar y Ticket)
  final GlobalKey _chargeFabKey = GlobalKey();
  final GlobalKey _confirmSaleKey = GlobalKey();
  final GlobalKey _totalAmountKey = GlobalKey();
  final GlobalKey _paymentMethodsKey = GlobalKey();
  final GlobalKey _discountKey = GlobalKey();

  // Flag para evitar múltiples inicializaciones
  bool _showcaseInitialized = false;
  bool _showcasePart2Initialized = false;
  bool _showcasePart3Initialized = false;

  /// Verifica si hay algún diálogo o modal abierto sobre la página actual
  /// Retorna true si la página de ventas NO es la ruta actual (hay algo encima)
  bool get _hasModalOnTop {
    final route = ModalRoute.of(context);
    // Si no hay ruta o la ruta no es la actual, hay algo encima
    return route != null && !route.isCurrent;
  }

  @override
  void initState() {
    super.initState();
    _scannerInputController = _ScannerInputController(
      onScannerCodeDetected: (code) => scanCodeProduct(code: code),
      requestManualDialog: _handleManualEntryRequested,
      closeManualDialog: _closeManualInputDialog,
      isManualDialogOpen: () => _isDialogOpen,
    );
    // NO activar listener aquí - se activará en didChangeDependencies
    // cuando se confirme que la página está visible

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detectar si esta página está visible usando HomeProvider
    final homeProvider = Provider.of<HomeProvider>(context, listen: true);
    final shouldBeActive = homeProvider.isSellPage;

    final currentIndex = homeProvider.currentPageIndex;
    // Detectar si acabamos de volver a la página de ventas desde otra pestaña
    if (_lastHomePageIndex != null &&
        _lastHomePageIndex != 0 &&
        currentIndex == 0) {
      _skipExitDialogOnce = true; // Evitar diálogo al volver desde otra pestaña
    } else if (currentIndex == 0 && _lastHomePageIndex == 0) {
      // Estamos consistentemente en ventas, asegurar que el diálogo puede aparecer
      _skipExitDialogOnce = false;
    }
    _lastHomePageIndex = currentIndex;

    // Activar/desactivar listener según visibilidad de la página
    if (shouldBeActive && !_isListenerActive) {
      _activateListener();
    } else if (!shouldBeActive && _isListenerActive) {
      _deactivateListener();
    }
  }

  @override
  void dispose() {
    _deactivateListener(); // Asegurar desactivación al destruir
    _focusNode.dispose();
    _scannerInputController.dispose();
    _scanAudioPlayer.dispose();
    super.dispose();
  }

  /// Activa el listener del teclado/escáner
  void _activateListener() {
    if (!_isListenerActive) {
      HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      _isListenerActive = true;
      _focusNode.requestFocus(); // Enfocar para recibir eventos
    }
  }

  /// Desactiva el listener del teclado/escáner
  void _deactivateListener() {
    if (_isListenerActive) {
      HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
      _isListenerActive = false;
      _scannerInputController
          .clearManualInput(); // Limpiar buffer al desactivar
      if (_isDialogOpen) {
        _closeManualInputDialog(
            resetBuffer: true); // Cerrar diálogo si está abierto
      }
    }
  }

  /// Verifica si es la primera vez que se muestra el showcase
  Future<bool> _shouldShowShowcase() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('sales_page_showcase_shown') ?? false);
  }

  /// Marca el showcase como mostrado
  Future<void> _markShowcaseAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sales_page_showcase_shown', true);
  }

  /// Inicia el showcase
  void _startShowcase(BuildContext context) {

    // showcasewiget : se ejecuta solo una vez al iniciar la página para tutotial de uso por primera vez
    ShowCaseWidget.of(context).startShowCase([
      _quickSaleKey,
      _cashRegisterKey,
      _lastTicketKey,
      _printerKey,
      _searchProductKey,
      _favoritesKey,
    ]);
  }

  /// Verifica y inicia el showcase si corresponde
  Future<void> _checkAndStartShowcase(BuildContext showcaseContext) async {
    // Evitar múltiples inicializaciones
    if (_showcaseInitialized) return;
    
    final shouldShow = await _shouldShowShowcase();
    if (!shouldShow) return;
    
    // Esperar a que el widget tree esté completamente construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Delay adicional para asegurar que ShowCaseWidget esté listo
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        
        // Verificar que la página de ventas esté activa antes de mostrar el showcase
        // Esto previene que se inicie simultáneamente con showcases de otras páginas
        final homeProvider = Provider.of<HomeProvider>(context, listen: false);
        if (homeProvider.currentPageIndex != 0) {
          // Si no estamos en la página correcta, permitir retry cuando se navegue aquí
          return;
        }
        
        // Solo marcar como inicializado después de verificar que vamos a mostrar el showcase
        _showcaseInitialized = true;
        _markShowcaseAsShown();
        _startShowcase(showcaseContext);
      });
    });
  }

  // --- Lógica Parte 2 y 3 ---

  Future<bool> _shouldShowShowcasePart2() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('sales_page_showcase_part2_shown') ?? false);
  }

  Future<void> _markShowcasePart2AsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sales_page_showcase_part2_shown', true);
  }

  Future<bool> _shouldShowShowcasePart3() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('sales_page_showcase_part3_shown') ?? false);
  }

  Future<void> _markShowcasePart3AsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sales_page_showcase_part3_shown', true);
  }

  void _checkAndStartShowcasePart2(BuildContext context, bool isMobileDevice) async {
    if (_showcasePart2Initialized) return;
    
    final shouldShow = await _shouldShowShowcasePart2();
    if (!shouldShow) return;

    _showcasePart2Initialized = true;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _markShowcasePart2AsShown();
          if (isMobileDevice) {
             // Móvil: Solo mostrar botón cobrar
             ShowCaseWidget.of(context).startShowCase([_chargeFabKey]);
          } else {
             // Desktop: Mostrar contenido del ticket directamente
             ShowCaseWidget.of(context).startShowCase([
               _confirmSaleKey,
               _totalAmountKey,
               _paymentMethodsKey,
               _discountKey,
             ]);
          }
        }
      });
    });
  }

  void _checkAndStartShowcasePart3(BuildContext context) async {
    if (_showcasePart3Initialized) return;
    
    final shouldShow = await _shouldShowShowcasePart3();
    if (!shouldShow) return;

    _showcasePart3Initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _markShowcasePart3AsShown();
          ShowCaseWidget.of(context).startShowCase([
             _confirmSaleKey,
             _totalAmountKey,
             _paymentMethodsKey,
             _discountKey,
          ]);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // consumer : escucha los cambios en ventas (SalesProvider) y el catalogo (CatalogueProvider)
    return ShowCaseWidget(
      builder: (context) => Builder(
        builder: (builderContext) {
          // Iniciar showcase automáticamente si es la primera vez
          _checkAndStartShowcase(builderContext);
          
          return Consumer2<SalesProvider, CatalogueProvider>(
            builder: (_, sellProvider, catalogueProvider, __) {
              // --- account demo : Si la cuenta seleccionada es demo y usuario anónimo, cargar productos demo. ---
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              // Si es cuenta demo y usuario anónimo, cargar productos demo
              if (sellProvider.profileAccountSelected.id == 'demo' && authProvider.user?.isAnonymous == true && catalogueProvider.products.isEmpty) {
                // Usar servicio de datos demo
                final service = DemoAccountService();
                final demoProducts = service.products;
                final demoCategories = service.categories;
                final demoProviders = service.providers;
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  catalogueProvider.loadDemoProducts(
                    products: demoProducts,
                    categories: demoCategories,
                    providers: demoProviders,
                  );
                });
              }

              // inicialiar [initializeFromPersistence]

              final isMobileDevice = isMobile(context);
              final hasProducts = sellProvider.ticket.getProductsQuantity() > 0;
              final isTicketViewOpen = sellProvider.ticketView;

              // Chequear Parte 2 y 3 del tutorial
              if (hasProducts) {
                 if (isMobileDevice) {
                    // Si es móvil, activar Parte 2 (botón cobrar)
                    _checkAndStartShowcasePart2(builderContext, true);
                    
                    // Si además abrió el ticket, activar Parte 3 (contenido ticket)
                    if (isTicketViewOpen) {
                       _checkAndStartShowcasePart3(builderContext);
                    }
                 } else {
                    // Desktop: Activar Parte 2 (contenido ticket directo)
                    _checkAndStartShowcasePart2(builderContext, false);
                 }
              }

              // --- pantalla principal de venta ---
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop) return;

                  // Evitar mostrar el diálogo inmediatamente al volver desde otra pestaña
                  if (_skipExitDialogOnce) {
                    _skipExitDialogOnce = false;
                    return;
                  }

                  // Mostrar diálogo de confirmación para salir de la app
                  final shouldExit = await showConfirmationDialog(
                    context: context,
                    title: 'Salir de la aplicación',
                    message: '¿Estás seguro que deseas salir?',
                    confirmText: 'Salir',
                    cancelText: 'Cancelar',
                    icon: Icons.exit_to_app_rounded,
                    isDestructive: true,
                  );

                  // Si confirma, cerrar la aplicación
                  if (shouldExit == true) {
                    SystemNavigator.pop();
                  }
                },
                child: Scaffold(
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
                                Focus(
                                  focusNode: _focusNode,
                                  autofocus: true,
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
                              onConfirmSale: () => _confirmSale(
                                  sellProvider), // para confirmar la venta
                              onCloseTicket: _showConfirmedPurchase
                                  ? _onConfirmationComplete // Callback especial cuando está en modo confirmación
                                  : () => sellProvider.setTicketView(
                                      false), // para cerrar el ticket normalmente
                              confirmSaleKey: _confirmSaleKey,
                              totalAmountKey: _totalAmountKey,
                              paymentMethodsKey: _paymentMethodsKey,
                              discountKey: _discountKey,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // admin : Maneja los eventos de teclado crudos para detectar entradas del escáner y entrada manual
  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Ignorar eventos de teclado si hay cualquier diálogo/modal abierto
    // sobre la página de ventas (excepto el diálogo de búsqueda manual propio)
    if (_hasModalOnTop && !_isDialogOpen) return false;

    _scannerInputController.handleKeyInput(
      logicalKey: event.logicalKey,
      character: event.character,
    );

    return false;
  }

  void _handleManualEntryRequested() {
    if (_isDialogOpen || !mounted) return;
    _isDialogOpen = true;
    unawaited(_showSearchByNumberDialog());
  }

  void _closeManualInputDialog({bool resetBuffer = false}) {
    if (!_isDialogOpen) {
      if (resetBuffer) {
        _scannerInputController.clearManualInput();
      }
      return;
    }

    final dialogContext = _manualDialogContext ?? _focusNode.context;
    if (dialogContext != null && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }
    _isDialogOpen = false;
    _manualDialogContext = null;

    if (resetBuffer) {
      _scannerInputController.clearManualInput();
    }
  }

  /// Muestra un diálogo simple que captura la entrada numérica en tiempo real
  Future<void> _showSearchByNumberDialog() async {
    final context = _focusNode.context;
    if (context == null) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        _manualDialogContext = dialogContext;
        return _SearchNumberDialog(
          numberBufferNotifier: _scannerInputController.manualBuffer,
          onCancel: () {
            _scannerInputController.clearManualInput();
            Navigator.of(dialogContext).pop();
          },
          onSearch: () {
            final code = _scannerInputController.manualBuffer.value;
            _scannerInputController.clearManualInput();
            Navigator.of(dialogContext).pop();
            unawaited(scanCodeProduct(code: code));
          },
        );
      },
    ).then((_) {
      _scannerInputController.clearManualInput();
      _isDialogOpen = false;
      _manualDialogContext = null;
    });
  }

  /// Reproduce el sonido de escaneo cuando se encuentra un producto
  Future<void> _playScanSound() async {
    try {
      // Configurar volumen al máximo antes de reproducir
      await _scanAudioPlayer.setVolume(1.0);
      
      await _scanAudioPlayer.play(
        AssetSource('sounds/scan_bip.mp3'),
        volume: 1.0,
        mode: PlayerMode.lowLatency, // Baja latencia para web
      );
    } catch (e) {
      debugPrint('Error reproduciendo sonido de escaneo: $e');
    }
  }

  Future<void> scanCodeProduct({required String code}) async {
    final context = _focusNode.context;
    if (context == null) return;

    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);
    final homeProvider = Provider.of<SalesProvider>(context, listen: false);
    final product = catalogueProvider.getProductByCode(code);

    if (product != null &&
        product.id.isNotEmpty &&
        product.description.isNotEmpty) {
      // - Si se encuentra el producto en el catálogo con datos válidos -
      // Reproducir sonido de escaneo exitoso
      unawaited(_playScanSound());
      
      // Si es unidad fraccionaria, mostrar diálogo para elegir cantidad
      if (product.isFractionalUnit) {
        if (mounted) {
          showProductEditDialog(
            context,
            producto: product.copyWith(quantity: 1.0),
            onProductUpdated: () {},
          );
        }
      } else {
        // Unidad discreta: agregar directamente al ticket
        homeProvider.addProductsticket(product.copyWith());
      }
    } else {
      // Si no se encuentra el producto en el catálogo, buscar en la base pública
      final publicProduct =
          await catalogueProvider.getPublicProductByCode(code);

      if (publicProduct != null) {
        // Si se encuentra un producto público, reproducir sonido y mostrar el diálogo
        unawaited(_playScanSound());
        
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
              isNew: true,
              product: ProductCatalogue(
                id: code,
                code: code,
                creation: DateTime.now(),
                upgrade: DateTime.now(),
                documentCreation: DateTime.now(),
                documentUpgrade: DateTime.now(),
              ));
        }
      }
    }
  }
  // fin - admin : Maneja los eventos de teclado crudos para detectar entradas del escáner y entrada manual

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
                AppButton.outlined(
                  text: 'Cancelar',
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 12),
                // button : Agregar producto
                AppButton.primary(
                  text: 'Crear producto',
                  onPressed: () {
                    accionRealizada = true;
                    Navigator.of(context).pop();
                    showAddProductDialog(context,
                        isNew: true,
                        product: ProductCatalogue(
                          id: code,
                          code: code,
                          creation: DateTime.now(),
                          upgrade: DateTime.now(),
                          documentCreation: DateTime.now(),
                          documentUpgrade: DateTime.now(),
                        ));
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
      {required BuildContext buildContext, required SalesProvider provider}) {
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
    return CustomAppBar(
      automaticallyImplyLeading: false,
      titleWidget: Row(
        children: [
          // Botón de menú drawer
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menú',
            ),
          ),
          const SizedBox(width: 12),
          // button : busqueda de productos 
          Expanded(
            child: Showcase(
              key: _searchProductKey,
              title: '🔍 Busca tus Productos',
              description: 'Encuentra productos rápidamente escribiendo su nombre o código. También con el teclado puedes escribir o escanear códigos de barras directamente',
              targetBorderRadius: BorderRadius.circular(20),
              targetPadding: const EdgeInsets.all(8),
              child: SearchTextField.button(
                height: 40,
                onTap: (isLoading || isEmpty)
                    ? null
                    : () => showModalBottomSheetSelectProducts(buildContext),
                isLoading: isLoading,
                loadingWidget: isLoading
                    ? SizedBox(
                        width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(buildContext)
                              .colorScheme
                              .primaryContainer))
                  : null,
                label: textHintSearchButton,
              ),
            ),
          ),
          const SizedBox(width: 12), 
          // view : botones de la barra de acciones
          Row(
            children: [
              // button : botón de estado de la impresora
              Consumer<PrinterProvider>(
                builder: (context, printerProvider, __) {
                  final isConnected = printerProvider.isConnected;
                  return Showcase(
                    key: _printerKey,
                    title: '🖨️ Impresora',
                    description: 'Configura tu impresora térmica para imprimir tickets automáticamente. El indicador verde muestra cuando está conectada con una impresora física',
                    targetBorderRadius: BorderRadius.circular(50),
                    targetPadding: const EdgeInsets.all(8),
                    child: AppBarButtonCircle(
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
                    ),
                  );
                },
              ),

              // button : último ticket vendido
              Consumer<SalesProvider>(
                builder: (context, sellProvider, __) {
                  final hasLastTicket = sellProvider.lastSoldTicket != null;
                  return Showcase(
                    key: _lastTicketKey,
                    title: '🧾 Último Ticket',
                    description: 'Accede rápidamente al último ticket generado para consultarlo o reimprimirlo si es necesario',
                    targetBorderRadius: BorderRadius.circular(50),
                    targetPadding: const EdgeInsets.all(8),
                    child: AppBarButtonCircle(
                        icon: Icons.receipt_long_rounded,
                        tooltip: hasLastTicket
                            ? 'Ver último ticket\nToca para ver detalles y reimprimir'
                            : 'No hay tickets recientes',
                        onPressed: hasLastTicket
                            ? () =>
                                _showLastTicketDialog(buildContext, sellProvider)
                            : null,
                        backgroundColor: Theme.of(buildContext)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.4),
                        colorAccent: Theme.of(buildContext).colorScheme.primary),
                  );
                },
              ),

              // button : administrar caja
              Showcase(
                key: _cashRegisterKey,
                title: '🏦 Gestión de Caja',
                description: 'Abre, cierra y administra tu caja registradora. Controla el efectivo, registra movimientos y genera arqueos al final del día o turno',
                targetBorderRadius: BorderRadius.circular(50),
                targetPadding: const EdgeInsets.all(8),
                child: CashRegisterStatusWidget(),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Lógica para confirmar la venta y procesar el ticket
  Future<void> _confirmSale(SalesProvider provider) async {
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
      final provider = Provider.of<SalesProvider>(context, listen: false);
      provider.discartTicket();
      provider.setTicketView(false);
    }
  }

  /// Botones para la vista principal. Solo visible en móvil y cuando el ticket no está visible.
  Widget floatingActionButtonBody({required SalesProvider sellProvider}) {
    return Row(
      children: [
        // button : descartar ticket si es existente y tiene productos
        if (sellProvider.ticket.getProductsQuantity() > 0)
          AppButton.fab(
            heroTag: "discard_ticket_fab", // Hero tag único
            onPressed: () => discartTicketAlertDialg(),
            icon: Icons.close_rounded,
            backgroundColor: Colors.grey,
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
        const SizedBox(width: 8),
        // button : muestra el botón de venta rápida
        Showcase(
          key: _quickSaleKey,
          title: '⚡ Venta Rápida',
          description: 'Registra ventas al instante sin registro previo, ideal para ventas simples y rápidas',
          targetBorderRadius: BorderRadius.circular(50),
          targetPadding: const EdgeInsets.all(8),
          child: AppButton.fab(
            heroTag: "quick_sale_fab", // Hero tag único
            onPressed: () => showQuickSaleDialog(context, provider: sellProvider),
            icon: Icons.flash_on_rounded,
            backgroundColor: Colors.amber,
          ).animate(delay: const Duration(milliseconds: 0)).fade(),
        ),
        const SizedBox(width: 8),
        // button : muestra el botón de cobrar si es móvil y el ticket no está visible
        const SizedBox(width: 8),
        // button : muestra el botón de cobrar si es móvil y el ticket no está visible
        isMobile(context)
            ? Showcase(
                key: _chargeFabKey,
                title: '💰 Cobrar Ticket',
                description: 'Toca aquí para ver el resumen del ticket, seleccionar método de pago y finalizar la venta',
                targetBorderRadius: BorderRadius.circular(50),
                child: AppButton.fab(
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
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  /// Construye el grid de productos y celdas vacías para llenar toda la vista sin espacios vacíos.
  Widget body({required SalesProvider provider}) {
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
                  return ProductItem(producto: list[index]);
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
  Widget _buildFavoriteProductsRow(SalesProvider provider) {
    final catalogueProvider =
        Provider.of<CatalogueProvider>(context, listen: false);

    // Usar el método del provider para obtener productos más vendidos
    final displayProducts = catalogueProvider.getTopFilterProducts();

    // Si no hay productos con ventas, no mostrar nada
    if (displayProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Showcase(
      key: _favoritesKey,
      title: '⭐ Favoritos y Productos Recientes',
      description: 'Acceso rápido a tus productos. Toca cualquiera para agregarlo al ticket',
      targetBorderRadius: BorderRadius.circular(12),
      targetPadding: const EdgeInsets.all(8),
      child: Container(
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
                        // Si es unidad fraccionaria, mostrar diálogo para elegir cantidad
                        if (product.isFractionalUnit) {
                          showProductEditDialog(
                            context,
                            producto: product.copyWith(quantity: 1.0),
                            onProductUpdated: () {},
                          );
                        } else {
                          // Unidad discreta: agregar directamente al ticket
                          provider.addProductsticket(product.copyWith());
                        }
                      },
                    ),
                  );
                },
              ))),
    );
  }

  Widget paymentMethodChips() {
    final provider = Provider.of<SalesProvider>(context, listen: false);
    return Wrap(
      spacing: 5,
      alignment: WrapAlignment.center,
      runSpacing: 5,
      children: PaymentMethod.getValidMethods().map((method) {
        final isSelected = provider.ticket.payMode == method.code;
        return ChoiceChip(
          avatar: Icon(
            method.icon,
            size: 18,
            color: isSelected ? Colors.white : null,
          ),
          label: Text(method.displayName),
          selected: isSelected,
          onSelected: (bool selected) {
            if (selected && method == PaymentMethod.cash) {
              dialogSelectedIncomeCash();
            }
            provider.setPayMode(payMode: selected ? method.code : '');
          },
        );
      }).toList(),
    );
  }

  /// Muestra un diálogo para ingresar el monto recibido, con formateo y cálculo de vuelto.
  void dialogSelectedIncomeCash({double? initialAmount}) {
    final provider = Provider.of<SalesProvider>(context, listen: false);
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

            return BaseDialog(
              title: 'Cobro en efectivo',
              icon: Icons.payments_outlined,
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
                  const SizedBox(height: 20),
                  // Contenedor destacado para Total y Vuelto
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: 1),
                    ),
                    child: Column(
                      children: [
                        // Fila del Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.formatPrice(value: total),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Divider(
                          height: 1,
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 12),
                        // Fila del Vuelto
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Vuelto:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.8),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: vuelto < 0
                                    ? theme.colorScheme.error
                                        .withValues(alpha: 0.12)
                                    : theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: theme.textTheme.headlineSmall!.copyWith(
                                  color: vuelto < 0
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: Text(
                                  CurrencyFormatter.formatPrice(
                                      value: vuelto < 0 ? 0 : vuelto),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                Provider.of<SalesProvider>(this.context, listen: false)
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
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);
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
      required SalesProvider sellProvider,
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
            productDescription: product.description,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedProduct.formattedQuantityCompact,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
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
void _showLastTicketDialog(BuildContext context, SalesProvider provider) {
  if (provider.lastSoldTicket == null) return; // No hay ticket para mostrar
  final ticket = provider.lastSoldTicket!;

  showTicketDetailDialog(
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
    final sellProvider = context.read<SalesProvider>();
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

  // - Muestra el diálogo con acciones de caja registradora -
  // - Muestra el diálogo con acciones de caja registradora -
  void _showStatusDialog(BuildContext context) {
    // - obtenemos los proveedores necesarios para el diálogo
    final cashRegisterProvider =
        Provider.of<CashRegisterProvider>(context, listen: false);
    final sellProvider = Provider.of<SalesProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Obtener el balance esperado desde las métricas cacheadas (más preciso)
    // Las métricas incluyen tickets y movimientos de caja en tiempo real
    final balance = cashRegisterProvider.cachedMetrics?.expectedBalance ?? 
        (cashRegisterProvider.currentActiveCashRegister?.getExpectedBalance ?? 0.0);

    final theme = Theme.of(context);
    
    // Capturar el contexto original que tiene acceso a los providers
    final originalContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => BaseDialog(
        title: 'Caja Registradora',
        subtitle: 'Balance actual: ${CurrencyFormatter.formatPrice(value: balance)}',
        icon: Icons.point_of_sale_rounded,
        width: isMobile(context) ? null : 450,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Descripción
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Selecciona una acción para gestionar tu caja',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // 1. Botón de Ingreso
            if (cashRegisterProvider.hasActiveCashRegister)
              _buildLargeActionButton(
                dialogContext,
                originalContext: originalContext,
                icon: Icons.arrow_downward_rounded,
                label: 'Ingreso',
                description: 'Registrar entrada de dinero',
                color: Colors.green,
                onTap: () => _showCashFlowDialog(
                    originalContext, true, cashRegisterProvider, sellProvider, authProvider),
              ),
            
            const SizedBox(height: 12),
            
            // 2. Botón de Egreso
            if (cashRegisterProvider.hasActiveCashRegister)
              _buildLargeActionButton(
                dialogContext,
                originalContext: originalContext,
                icon: Icons.arrow_upward_rounded,
                label: 'Egreso',
                description: 'Registrar salida de dinero',
                color: Colors.orange,
                onTap: () => _showCashFlowDialog(
                    originalContext, false, cashRegisterProvider, sellProvider, authProvider),
              ),
            
            const SizedBox(height: 12),
            
            // 3. Botón de Cerrar Caja
            if (cashRegisterProvider.hasActiveCashRegister)
              _buildLargeActionButton(
                dialogContext,
                originalContext: originalContext,
                icon: Icons.lock_rounded,
                label: 'Cerrar Caja',
                description: 'Finalizar turno y arqueo',
                color: theme.colorScheme.error,
                onTap: () => _showCloseCashRegisterDialog(
                    originalContext, cashRegisterProvider, sellProvider),
              ),
            
            const SizedBox(height: 16),
            
            // Link a vista detallada
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Future.delayed(const Duration(milliseconds: 50));
                if (!originalContext.mounted) return;
                // ignore: use_build_context_synchronously
                CashRegisterManagementDialog.showAdaptive(originalContext);
              },
              icon: Icon(Icons.open_in_new_rounded, size: 18),
              label: Text('Ver detalles completos'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          DialogComponents.secondaryActionButton(
            context: dialogContext,
            text: 'Cerrar',
            onPressed: () => Navigator.pop(dialogContext),
          )
        ],
      ),
    );
  }

  /// Construye un botón grande de acción siguiendo Material Design 3
  Widget _buildLargeActionButton(
    BuildContext context, {
    required BuildContext originalContext,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return FilledButton.tonal(
      onPressed: () {
        Navigator.pop(context);
        onTap();
      },
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Indicador de acción
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  // - Reutiliza CashFlowDialog para mostrar diálogo de ingresos/egresos -
  void _showCashFlowDialog(
      BuildContext context,
      bool isInflow,
      CashRegisterProvider cashRegisterProvider,
      SalesProvider sellProvider,
      AuthProvider authProvider) {
    if (!cashRegisterProvider.hasActiveCashRegister) return;

    final cashRegister = cashRegisterProvider.currentActiveCashRegister!;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: CashFlowDialog(
          isInflow: isInflow,
          cashRegisterId: cashRegister.id,
          accountId: sellProvider.profileAccountSelected.id,
          userId: authProvider.user?.email ?? '',
          fullView: true,
        ),
      ),
    );
  }

  // - Reutiliza CashRegisterCloseDialog para mostrar diálogo de cierre -
  void _showCloseCashRegisterDialog(BuildContext context,
      CashRegisterProvider cashRegisterProvider, SalesProvider sellProvider) {
    final currentCashRegister = cashRegisterProvider.currentActiveCashRegister;
    if (currentCashRegister == null) return;

    showDialog(
      context: context,
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CashRegisterProvider>.value(
              value: cashRegisterProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: sellProvider),
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
    // Verificar permisos de arqueo
    final sellProvider = context.watch<SalesProvider>();
    final adminProfile = sellProvider.currentAdminProfile;
    
    // Si no tiene permiso de arqueo, no mostrar el widget
    final hasArqueoPermission = adminProfile?.hasPermission(AdminPermission.createCashCount) ?? false;
    if (!hasArqueoPermission) {
      return const SizedBox.shrink();
    }

    // consumer : obtiene el estado de la caja registradora
    return Consumer<CashRegisterProvider>(
      builder: (context, provider, child) {
        final bool isActive = provider.hasActiveCashRegister;
        final int salesCount = provider.currentActiveCashRegister?.sales ?? 0;
        final String cashRegisterDescription = 
            provider.currentActiveCashRegister?.description ?? '';

        // button : boton con el estado de la caja registradora
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // boton de caja registradora
            AppBarButtonCircle(
              isLoading: _isInitializing,
              icon: Icons.point_of_sale_outlined,
              tooltip: isActive 
                  ? 'Caja: $cashRegisterDescription' 
                  : 'Abrir caja',
              onPressed: () {
                // Si no hay caja activa, abrir directamente el administrador de caja
                if (!isActive) {
                  _showCashRegisterManagementDialog(context);
                } else {
                  // Si hay caja activa, mostrar el diálogo de estado
                  _showStatusDialog(context);
                }
              },
              backgroundColor:
                  isActive ? Colors.green.withValues(alpha: 0.1) : null,
              colorAccent: isActive ? Colors.green.shade700 : null,
              text: isMobile(context)
                  ? null
                  : (isActive ? cashRegisterDescription : 'Abrir caja'),
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

/// Widget de diálogo para mostrar la búsqueda por número en tiempo real
class _SearchNumberDialog extends StatelessWidget {
  final ValueNotifier<String> numberBufferNotifier;
  final VoidCallback onCancel;
  final VoidCallback onSearch;

  const _SearchNumberDialog({
    required this.numberBufferNotifier,
    required this.onCancel,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: numberBufferNotifier,
      builder: (context, currentBuffer, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // Texto de búsqueda
              Text(
                'CÓDIGO',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              // Mostrar números ingresados con animación
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    currentBuffer.isEmpty ? '...' : currentBuffer,
                    key: ValueKey(currentBuffer),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: currentBuffer.isEmpty ? null : onSearch,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Buscar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Handles barcode bursts versus manual typing and notifies the page accordingly.
class _ScannerInputController {
  _ScannerInputController({
    required Future<void> Function(String code) onScannerCodeDetected,
    required VoidCallback requestManualDialog,
    required bool Function() isManualDialogOpen,
    required void Function({bool resetBuffer}) closeManualDialog,
  })  : _onScannerCodeDetected = onScannerCodeDetected,
        _requestManualDialog = requestManualDialog,
        _isManualDialogOpen = isManualDialogOpen,
        _closeManualDialog = closeManualDialog;

  static const Duration _scannerKeyInterval = Duration(milliseconds: 35);
  static const Duration _manualResetInterval = Duration(milliseconds: 500);
  static const Duration _scannerProcessDelay = Duration(milliseconds: 100);
  static const Duration _scannerSequenceMaxDuration =
      Duration(milliseconds: 600);
  static const int _scannerMinLength = 6;
  static final RegExp _numericRegExp = RegExp(r'^[0-9]$');

  final Future<void> Function(String code) _onScannerCodeDetected;
  final VoidCallback _requestManualDialog;
  final bool Function() _isManualDialogOpen;
  final void Function({bool resetBuffer}) _closeManualDialog;

  final ValueNotifier<String> manualBuffer = ValueNotifier<String>('');

  DateTime? _lastKey;
  final StringBuffer _scannerBuffer = StringBuffer();
  Timer? _scannerProcessingTimer;
  bool _scannerCandidateActive = false;
  DateTime? _scannerSequenceStart;
  String _manualPendingCandidate = '';

  void handleKeyInput({
    required LogicalKeyboardKey logicalKey,
    String? character,
  }) {
    if (logicalKey == LogicalKeyboardKey.backspace) {
      _handleBackspace();
      return;
    }

    if (logicalKey == LogicalKeyboardKey.enter) {
      if (_scannerCandidateActive &&
          _scannerBuffer.isNotEmpty &&
          _scannerBuffer.length >= _scannerMinLength) {
        _finalizeScannerCandidate(forceScanner: true);
      }
      return;
    }

    final char = character;
    if (char == null || !_numericRegExp.hasMatch(char)) {
      return;
    }

    final previousTimestamp = _lastKey;
    final now = DateTime.now();
    final diff =
        previousTimestamp == null ? null : now.difference(previousTimestamp);
    _lastKey = now;

    final bool isNewSequence = diff == null || diff > _manualResetInterval;
    final bool shouldResetManual = !_isManualDialogOpen() && isNewSequence;
    final bool isRapidInput = diff != null && diff <= _scannerKeyInterval;

    if (_isManualDialogOpen()) {
      if (isRapidInput) {
        _appendScannerCharacter(char, now, previousTimestamp);
        return;
      }
      _cancelScannerCandidate();
      _updateManualInputBuffer(char, false);
      return;
    }

    if (isRapidInput) {
      _appendScannerCharacter(char, now, previousTimestamp);
      return;
    }

    _flushScannerCandidateAsManual(shouldReset: shouldResetManual);
    _updateManualInputBuffer(char, shouldResetManual);
  }

  void dispose() {
    manualBuffer.dispose();
    _scannerProcessingTimer?.cancel();
  }

  void clearManualInput() {
    manualBuffer.value = '';
    _manualPendingCandidate = '';
  }

  void _handleBackspace() {
    if (manualBuffer.value.isEmpty) {
      _manualPendingCandidate = '';
      return;
    }
    manualBuffer.value =
        manualBuffer.value.substring(0, manualBuffer.value.length - 1);
    _manualPendingCandidate = manualBuffer.value;
  }

  void _appendScannerCharacter(
    String char,
    DateTime timestamp,
    DateTime? previousTimestamp,
  ) {
    if (!_scannerCandidateActive) {
      _scannerCandidateActive = true;
      _scannerSequenceStart = previousTimestamp ?? timestamp;
      final manualPrefix = _manualPendingCandidate;
      _manualPendingCandidate = '';
      if (manualPrefix.isNotEmpty) {
        _closeManualDialog(resetBuffer: true);
      }
      _scannerBuffer
        ..clear()
        ..write(manualPrefix);
    }
    _scannerBuffer.write(char);
    _scheduleScannerProcessing();
  }

  void _scheduleScannerProcessing() {
    _scannerProcessingTimer?.cancel();
    _scannerProcessingTimer = Timer(
      _scannerProcessDelay,
      _finalizeScannerCandidate,
    );
  }

  void _finalizeScannerCandidate({bool forceScanner = false}) {
    if (!_scannerCandidateActive || _scannerBuffer.isEmpty) {
      _cancelScannerCandidate();
      return;
    }

    final code = _scannerBuffer.toString();
    final elapsed = _scannerSequenceStart == null
        ? null
        : DateTime.now().difference(_scannerSequenceStart!);

    final qualifiesAsScanner = forceScanner ||
        (code.length >= _scannerMinLength &&
            elapsed != null &&
            elapsed <= _scannerSequenceMaxDuration);

    _cancelScannerCandidate();

    if (qualifiesAsScanner) {
      _handleScannerDetection(code);
    } else {
      _injectManualFromCode(code, shouldReset: true);
    }
  }

  void _flushScannerCandidateAsManual({required bool shouldReset}) {
    if (!_scannerCandidateActive || _scannerBuffer.isEmpty) {
      _cancelScannerCandidate();
      return;
    }
    final code = _scannerBuffer.toString();
    _cancelScannerCandidate();
    _injectManualFromCode(code, shouldReset: shouldReset);
  }

  void _injectManualFromCode(String code, {required bool shouldReset}) {
    if (code.isEmpty) return;
    var resetFlag = shouldReset;
    for (final char in code.split('')) {
      _updateManualInputBuffer(char, resetFlag);
      resetFlag = false;
    }
  }

  void _cancelScannerCandidate({bool clearBuffer = true}) {
    _scannerCandidateActive = false;
    _scannerSequenceStart = null;
    _scannerProcessingTimer?.cancel();
    if (clearBuffer) {
      _scannerBuffer.clear();
    }
  }

  void _handleScannerDetection(String code) {
    if (code.isEmpty) return;
    _closeManualDialog(resetBuffer: true);
    unawaited(_onScannerCodeDetected(code));
  }

  void _updateManualInputBuffer(String char, bool shouldReset) {
    if (shouldReset) {
      clearManualInput();
    }
    manualBuffer.value += char;
    _manualPendingCandidate += char;
    if (!_isManualDialogOpen()) {
      _requestManualDialog();
    }
  }
}
