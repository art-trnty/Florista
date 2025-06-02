import 'dart:convert';
import 'dart:typed_data';

import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/AdditionalFeaturesScreen/ProfileDetailScreens.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/StoreDetailScreen.dart';
import 'package:flutter/material.dart';

class FavoriteStoreScreen extends StatefulWidget {
  final List<String> favoriteStoreIds;
  final List<StoreModel> allStores;
  final String? currentUserUid;

  const FavoriteStoreScreen({
    super.key,
    required this.favoriteStoreIds,
    required this.allStores,
    this.currentUserUid,
  });

  @override
  State<FavoriteStoreScreen> createState() => _FavoriteStoreScreenState();
}

class _FavoriteStoreScreenState extends State<FavoriteStoreScreen> {
  int _selectedIndex = 2;

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String.split(',').last);
    } catch (e) {
      return null;
    }
  }

  void _onItemTapped(int index) {
    if (index == 2) return; // Sudah di halaman Favorite

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst); // Balik ke Home
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllStoresScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteStores =
        widget.allStores
            .where((store) => widget.favoriteStoreIds.contains(store.id))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Toko Favorit"),
        backgroundColor: Colors.green[700],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
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
