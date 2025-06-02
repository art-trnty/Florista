import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final String imageBase64;
  final DateTime createdAt;
  final String owner;

  ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageBase64,
    required this.createdAt,
    required this.owner,
  });

  /// Convert model to Firestore map (excluding `id`)
  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'name': name,
      'description': description,
      'price': price,
      'imageBase64': imageBase64,
      'createdAt': Timestamp.fromDate(createdAt),
      'owner': owner,
    };
  }

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      storeId: map['storeId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageBase64: map['imageBase64'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      owner: map['owner'] ?? '',
    );
  }
}
