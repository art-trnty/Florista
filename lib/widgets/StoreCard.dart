import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:florista/models/StoreModel.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final String? currentUserUid;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;

  const StoreCard({
    super.key,
    required this.store,
    this.currentUserUid,
    this.onDelete,
    this.onToggleFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final Uint8List imageBytes = base64Decode(store.imageBase64);
    final bool isOwner = currentUserUid == store.owner;
    final double rating = store.rating ?? 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7;

    return SizedBox(
      width: cardWidth,
      height: 220,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.memory(
                imageBytes,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        IconButton(
                          icon: Icon(
                            isOwner
                                ? Icons.delete
                                : (isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border),
                            color: isOwner ? Colors.red : Colors.green,
                            size: 20,
                          ),
                          onPressed: () async {
                            if (isOwner) {
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
                                              () =>
                                                  Navigator.pop(context, false),
                                          child: const Text("Batal"),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(context, true),
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
                            } else {
                              if (onToggleFavorite != null) {
                                onToggleFavorite!();
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ..._buildRatingStars(rating),
                        const SizedBox(width: 4),
                        if (rating > 0)
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    Row(
                      children: const [
                        Icon(Icons.verified, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text("Verified", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, size: 14, color: Colors.amber));
    }

    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, size: 14, color: Colors.amber));
    }

    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, size: 14, color: Colors.amber));
    }

    return stars;
  }
}
