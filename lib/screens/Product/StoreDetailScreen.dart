import 'dart:convert';
import 'package:florista/widgets/ProductGrid.dart';
import 'package:florista/widgets/StoreHeader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:florista/AddProductScreen.dart';
import 'package:florista/models/ProductModel.dart';
import 'package:florista/screens/Product/EditProductScreen.dart';
import 'package:florista/models/StoreModel.dart';

class StoreDetailScreen extends StatefulWidget {
  final StoreModel store;

  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> selectedProductIds = [];
  bool isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final isOwner =
        FirebaseAuth.instance.currentUser?.uid == widget.store.owner;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Store"),
        backgroundColor: Colors.green,
        actions: [
          if (isOwner && selectedProductIds.isNotEmpty)
            IconButton(
              icon:
                  isDeleting
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.delete_forever),
              onPressed: isDeleting ? null : _deleteSelectedProducts,
            ),
        ],
      ),
      body: Column(
        children: [
          StoreHeader(store: widget.store),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari produk...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: const TabBar(
                      labelColor: Colors.green,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(text: 'Product'),
                        Tab(text: 'Discount'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ProductGrid(
                          storeId: widget.store.id,
                          isOwner: isOwner,
                          searchQuery: _searchController.text,
                          selectedProductIds: selectedProductIds,
                          onToggleSelection: (id) {
                            setState(() {
                              selectedProductIds.contains(id)
                                  ? selectedProductIds.remove(id)
                                  : selectedProductIds.add(id);
                            });
                          },
                        ),
                        const Center(child: Text("No discount available.")),
                        const Center(child: Text("No reviews yet.")),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          isOwner
              ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AddProductScreen(
                            storeId: widget.store.id,
                            ownerId: widget.store.owner,
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah Produk"),
                backgroundColor: Colors.green,
              )
              : null,
    );
  }

  Future<void> _deleteSelectedProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Hapus Produk"),
            content: Text(
              "Yakin ingin menghapus ${selectedProductIds.length} produk?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus"),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() => isDeleting = true);
      for (final id in selectedProductIds) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(id)
            .delete();
      }

      setState(() {
        selectedProductIds.clear();
        isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Produk berhasil dihapus.")));
    }
  }
}
