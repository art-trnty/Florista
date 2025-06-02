import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:florista/models/ProductModel.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTapFavorite;
  final VoidCallback? onTapEdit; // optional edit
  final VoidCallback? onTapDelete; // optional delete
  final bool showAdminControls;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTapFavorite,
    this.onTapEdit,
    this.onTapDelete,
    this.showAdminControls = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List imageBytes = base64Decode(product.imageBase64);

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),

          // Nama Produk
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),

          // Harga Produk
          Text(
            "Rp ${product.price.toStringAsFixed(0)}",
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 4),

          // Deskripsi (opsional)
          if (product.description.isNotEmpty)
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),

          const SizedBox(height: 8),

          // Tanggal dibuat + Tombol
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dibuat: ${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              Row(
                children: [
                  if (onTapFavorite != null)
                    IconButton(
                      onPressed: onTapFavorite,
                      icon: const Icon(Icons.favorite_border, size: 20),
                    ),
                  if (showAdminControls) ...[
                    IconButton(
                      onPressed: onTapEdit,
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      onPressed: onTapDelete,
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
