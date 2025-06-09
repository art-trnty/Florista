import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';

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

  void _launchEmail(BuildContext context, String email) async {
    final url = 'mailto:$email';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka aplikasi email")),
      );
    }
  }

  void _launchMapFromAddress(BuildContext context, String address) async {
    final encodedAddress = Uri.encodeComponent(address);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka alamat di Google Maps")),
      );
    }
  }

  void _launchSMS(BuildContext context, String phoneNumber) async {
    final url = 'sms:$phoneNumber';

    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka aplikasi pesan")),
      );
    }
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
              const SizedBox(height: 4),
              _buildInfoTile("Nama Toko", data['name'], Icons.store),
              _buildInfoTile(
                "Deskripsi Toko",
                data['description'],
                Icons.description,
              ),
              _buildInfoTile(
                "Alamat",
                data['address'],
                Icons.location_on,
                onTap: () => _launchMapFromAddress(context, data['address']),
              ),
              _buildInfoTile(
                "Email",
                data['email'],
                Icons.email,
                onTap: () => _launchEmail(context, data['email']),
              ),
              _buildInfoTile("Pemilik", data['ownerName'], Icons.person),
              _buildInfoTile(
                "No HP",
                data['phone'],
                Icons.phone,
                onTap: () => _launchSMS(context, data['phone']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(
    String title,
    dynamic value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(
          value != null && value.toString().isNotEmpty ? value.toString() : '-',
          style: TextStyle(
            color: onTap != null ? Colors.blue : null,
            decoration: onTap != null ? TextDecoration.underline : null,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
