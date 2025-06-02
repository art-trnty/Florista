import 'dart:convert';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/Store/StoreDetailScreen.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class FavoriteStoreScreen extends StatelessWidget {
  final List<String> favoriteStoreIds;
  final List<StoreModel> allStores;

  const FavoriteStoreScreen({
    super.key,
    required this.favoriteStoreIds,
    required this.allStores,
  });

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStores =
        allStores
            .where((store) => favoriteStoreIds.contains(store.id))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Toko Favorit"),
        backgroundColor: Colors.green[700],
      ),
      body:
          favoriteStores.isEmpty
              ? const Center(child: Text("Belum ada toko favorit."))
              : ListView.builder(
                itemCount: favoriteStores.length,
                itemBuilder: (context, index) {
                  final store = favoriteStores[index];
                  final imageBytes = decodeBase64Image(store.imageBase64);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => StoreDetailScreen(store: store),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Gambar toko dari Base64
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  imageBytes != null
                                      ? Image.memory(
                                        imageBytes,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.store,
                                          size: 40,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 12),
                            // Info toko
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    store.description ?? 'Tidak ada deskripsi.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
