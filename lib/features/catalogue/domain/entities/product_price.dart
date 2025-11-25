import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPrice {
  final String id;
  final double price;
  final DateTime time;
  final String currencySign;
  final String province;
  final String town;
  
  // Data account
  final String idAccount;
  final String imageAccount;
  final String nameAccount;

  ProductPrice({
    required this.id,
    required this.idAccount,
    required this.imageAccount,
    required this.nameAccount,
    required this.price,
    required this.time,
    required this.currencySign,
    this.province = '',
    this.town = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idAccount': idAccount,
      'imageAccount': imageAccount,
      'nameAccount': nameAccount,
      'price': price,
      'time': Timestamp.fromDate(time),
      'currencySign': currencySign,
      'province': province,
      'town': town,
    };
  }
}
