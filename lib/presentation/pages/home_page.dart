import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:sellweb/domain/entities/catalogue.dart' hide Provider;
import '../providers/home_provider.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/producto_item.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _barcodeBuffer = '';

  DateTime? _lastKey;

  final FocusNode _focusNode = FocusNode();

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


    } else {
      print('3Key event not handled: event.runtimeType');
    }
  }

  void scanCodeProduct({required String code}) {
    final context = _focusNode.context;
    if (context == null) return;
    final catalogueProvider = Provider.of<CatalogueProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final product = catalogueProvider.getProductByCode(code);
    if (product != null) {
      homeProvider.addProduct(  product.convertProductCatalogue()
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto agregado: A${product.description}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto no encontrado: $code')),
      );
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

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeProvider, CatalogueProvider>(
      builder: (context, controller, catalogueProvider, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Vender')),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: _focusNode,
                      autofocus: true,
                      onKeyEvent: _onKey,
                      child: body(controller: controller),
                    ),
                  ),
                  // Aquí podrías agregar un drawerTicket adaptado a Provider si lo necesitas
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () { 
              // ... 
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget body({required HomeProvider controller}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth < 700
            ? 3
            : constraints.maxWidth < 900
                ? 4
                : 6;
        final List<ProductCatalogue> list = controller.selectedProducts.reversed.toList();
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
          ),
          itemCount: list.length + 18,
          itemBuilder: (context, index) {
            if (index < list.length) {
              return ProductoItem(producto: list[index]);
            } else {
              return Card(elevation: 0, color: Colors.grey.withOpacity(0.1));
            }
          },
        );
      },
    );
  }
}
