import 'package:florista/screens/Store/EditStoreScreen.dart';
import 'package:florista/widgets/ReviewSection.dart';
import 'package:florista/widgets/ProductGrid.dart';
import 'package:florista/widgets/StoreBiodata.dart';
import 'package:florista/widgets/StoreHeader.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:florista/AddProductScreen.dart';
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
  bool _isLoading = false;

  late StoreModel _store;

  @override
  void initState() {
    super.initState();
    _store = widget.store;
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == _store.owner;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Store',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(2.0, 2.0),
                blurRadius: 3.0,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: isOwner
                ? IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditStoreScreen(store: _store),
                  ),
                );
              },
            )
                : const Icon(Icons.store, color: Colors.white),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  StoreHeader(store: _store),
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
                                Tab(text: 'ProduK'),
                                Tab(text: 'Komentar'),
                                Tab(text: 'Biodata Toko'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                ProductGrid(
                                  storeId: _store.id,
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
                                ReviewSection(storeId: _store.id),
                                StoreBiodata(storeId: _store.id),
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
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AddProductScreen(
                            storeId: _store.id,
                            ownerId: _store.owner,
                          ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
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
