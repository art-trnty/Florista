import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/StoreModel.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final String? currentUserUid;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite; // ✅ Tambahan

  const StoreCard({
    super.key,
    required this.store,
    this.currentUserUid,
    this.onDelete,
    this.onFavorite, // ✅ Tambahan
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(store.imageBase64);
    final isOwner = currentUserUid == store.owner;

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar toko
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.memory(
              imageBytes,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          // Informasi toko
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama dan tombol aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // ✅ Tampilkan ikon sesuai role
                    isOwner
                        ? IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder:
                                  (_) => AlertDialog(
                                    title: const Text("Hapus Toko"),
                                    content: const Text(
                                      "Apakah Anda yakin ingin menghapus toko ini?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, false),
                                        child: const Text("Batal"),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => Navigator.pop(context, true),
                                        child: const Text(
                                          "Hapus",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm == true && onDelete != null) {
                              onDelete!();
                            }
                          },
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.favorite_border,
                            color: Colors.green,
                            size: 20,
                          ),
                          onPressed: () {
                            if (onFavorite != null) {
                              onFavorite!();
                            }
                          },
                        ),
                  ],
                ),

                const SizedBox(height: 4),

                // Alamat toko
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        store.address,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Estimasi waktu dummy
                Row(
                  children: const [
                    Icon(Icons.timer, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text("10–15 mins", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
