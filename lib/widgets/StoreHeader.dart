import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:florista/models/StoreModel.dart';

class StoreHeader extends StatelessWidget {
  final StoreModel store;

  const StoreHeader({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final imageBytes = base64Decode(store.imageBase64);

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
                    children: const [
                      Icon(Icons.location_on, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text("2 km"),
                      SizedBox(width: 8),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text("4.8"),
                      SizedBox(width: 8),
                      Icon(Icons.verified, size: 16, color: Colors.blue),
                      SizedBox(width: 4),
                      Text("Verified"),
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
}
