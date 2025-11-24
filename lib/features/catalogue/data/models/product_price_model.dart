import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product_price.dart';

/// Modelo de datos para ProductPrice con lógica de serialización.
class ProductPriceModel extends ProductPrice {
  ProductPriceModel({
    required super.id,
    required super.idAccount,
    required super.imageAccount,
    required super.nameAccount,
    required super.price,
    required super.time,
    required super.currencySign,
    super.province,
    super.town,
  });

  /// Crea una instancia desde un Map con soporte para nombres legacy
  factory ProductPriceModel.fromMap(Map<String, dynamic> data) {
    return ProductPriceModel(
      id: data['id'] ?? '',
      idAccount: data['idAccount'] ?? '',
      imageAccount: data.containsKey('imageAccount')
          ? data['imageAccount']
          : data['urlImageAccount'] ?? '',
      nameAccount: data['nameAccount'] ?? '',
      price: data.containsKey('price') ? data['price'] : data['precio'] ?? 0.0,
      time: _parseTimestamp(data.containsKey('time') ? data['time'] : data['timestamp']),
      currencySign: data.containsKey('currencySign')
          ? data['currencySign']
          : data['moneda'] ?? '',
      province: data.containsKey('province')
          ? data['province']
          : data['provincia'] ?? '',
      town: data.containsKey('town') ? data['town'] : data['ciudad'] ?? '',
    );
  }

  /// Convierte a Map para Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        "idAccount": idAccount,
        "imageAccount": imageAccount,
        "nameAccount": nameAccount,
        "price": price,
        "time": Timestamp.fromDate(time),
        "currencySign": currencySign,
        "province": province,
        "town": town,
      };

  /// Convierte a entidad de dominio
  ProductPrice toEntity() {
    return ProductPrice(
      id: id,
      idAccount: idAccount,
      imageAccount: imageAccount,
      nameAccount: nameAccount,
      price: price,
      time: time,
      currencySign: currencySign,
      province: province,
      town: town,
    );
  }

  /// Helper para parsear Timestamp a DateTime
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.now();
  }
}
