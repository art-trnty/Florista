import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String address;
  final String description;
  final String phone;
  final String email;
  final String imageBase64;
  final String owner;
  final double? rating;

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.phone,
    required this.email,
    required this.imageBase64,
    required this.owner,
    required this.rating,
  });

  factory StoreModel.fromMap(Map<String, dynamic> data, String docId) {
    return StoreModel(
      id: docId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      owner: data['owner'] ?? '',
      rating:
          (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'phone': phone,
      'email': email,
      'imageBase64': imageBase64,
      'owner': owner,
      'rating': rating ?? 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
