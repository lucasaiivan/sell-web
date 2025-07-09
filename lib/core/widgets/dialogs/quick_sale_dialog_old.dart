import 'package:flutter/material.dart';
import 'package:sellweb/core/utils/fuctions.dart';
import 'package:sellweb/core/widgets/inputs/input_text_field.dart';
import 'package:sellweb/core/widgets/inputs/money_input_text_field.dart';
import 'package:sellweb/core/widgets/buttons/app_button.dart';
import 'package:sellweb/core/widgets/feedback/app_feedback.dart';
import 'package:sellweb/presentation/providers/sell_provider.dart';

/// Muestra un diálogo para realizar una venta rápida
Future<void> showQuickSaleDialog(
  BuildContext context, {
  required SellProvider provider,
}) async {
  // Controllers
  final AppMoneyTextEditingController priceController =
      AppMoneyTextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  /// Función para procesar la venta rápida
  void processQuickSale() {
    if (priceController.doubleValue <= 0) {
      AppFeedback.showError(
        context,
        title: 'Error',
        message: 'El precio debe ser mayor a cero',
      );
      return;
    }

    provider.addQuickProduct(
      description: descriptionController.text,
      salePrice: priceController.doubleValue,
    );

    priceController.clear();
    descriptionController.clear();
    Navigator.of(context).pop();
  }

  await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding:
            const EdgeInsets.only(left: 20, right: 8, top: 16, bottom: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actionsPadding: const EdgeInsets.only(right: 20, left: 20, bottom: 20),
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Venta rápida',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              splashRadius: 18,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de precio
              MoneyInputTextField(
                controller: priceController,
                labelText: 'Precio',
                autofocus: true,
                onSubmitted: (value) => processQuickSale(),
              ),
              const SizedBox(height: 20),
              // Campo de descripción
              InputTextField(
                controller: descriptionController,
                labelText: 'Descripción (opcional)',
                hintText: 'Ingrese una descripción del producto',
                textInputAction: TextInputAction.done,
                onSubmitted: (value) => processQuickSale(),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Agregar producto',
              onPressed: processQuickSale,
              margin: EdgeInsets.zero,
            ),
          ),
        ],
      );
    },
  );
}
