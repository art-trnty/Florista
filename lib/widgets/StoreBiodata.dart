import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreBiodata extends StatelessWidget {
  final String storeId;

  const StoreBiodata({super.key, required this.storeId});

  Future<Map<String, dynamic>> _fetchStoreAndOwner() async {
    final storeDoc =
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .get();
    if (!storeDoc.exists) {
      throw Exception('Store not found');
    }

    final storeData = storeDoc.data()!;
    final ownerId = storeData['owner'];

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    final ownerName = userDoc.exists ? userDoc.data()!['name'] ?? '-' : '-';

    return {
      'name': storeData['name'] ?? '-',
      'description': storeData['description'] ?? '-',
      'address': storeData['address'] ?? '-',
      'email': storeData['email'] ?? '-',
      'phone': storeData['phone'] ?? '-',
      'ownerName': ownerName,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchStoreAndOwner(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Gagal memuat biodata toko.'));
        }

        final data = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                "Biodata Toko",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInfoTile("Nama Toko", data['name']),
              _buildInfoTile("Deskripsi", data['description']),
              _buildInfoTile("Alamat", data['address']),
              _buildInfoTile("Email", data['email']),
              _buildInfoTile("Pemilik", data['ownerName']),
              _buildInfoTile("No HP", data['phone']),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(String title, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(title),
        subtitle: Text(
          value != null && value.toString().isNotEmpty ? value.toString() : '-',
        ),
      ),
    );
  }
}
