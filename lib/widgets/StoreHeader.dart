import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:florista/models/StoreModel.dart';

class StoreHeader extends StatelessWidget {
  final StoreModel store;

  const StoreHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(store.imageBase64);
    final double rating = store.rating ?? 0.0;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            imageBytes,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(store.address),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      const Text("2 km"),
                      const SizedBox(width: 8),

                      // ★ Dynamic Stars
                      ..._buildRatingStars(rating),
                      const SizedBox(width: 8),
                      Text(
                        '${rating.toStringAsFixed(1)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(width: 8),
                      const Icon(Icons.verified, size: 16, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text("Verified"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, size: 16, color: Colors.amber));
    }

    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, size: 16, color: Colors.amber));
    }

    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, size: 16, color: Colors.amber));
    }

    return stars;
  }
}
