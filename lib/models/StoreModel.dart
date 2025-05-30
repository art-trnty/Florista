import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id; // <--- Tambahan untuk menyimpan document ID
  final String name;
  final String address;
  final String description;
  final String phone;
  final String email;
  final String imageBase64;
  final String owner; // <--- Tambahan untuk menyimpan UID pemilik

  StoreModel({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.phone,
    required this.email,
    required this.imageBase64,
    required this.owner,
  });

  // Factory untuk mengambil data dari Firestore dan menyimpan documentId
  factory StoreModel.fromMap(Map<String, dynamic> data, String docId) {
    return StoreModel(
      id: docId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      owner: data['owner'] ?? '', // penting untuk pengecekan pemilik
    );
  }

  // Konversi ke Map saat ingin menyimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'description': description,
      'phone': phone,
      'email': email,
      'imageBase64': imageBase64,
      'owner': owner, // wajib simpan UID pemilik toko
      'createdAt': FieldValue.serverTimestamp(), // ✅ WAJIB pakai ini!
    };
  }
}
