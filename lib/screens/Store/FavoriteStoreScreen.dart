import 'dart:convert';
import 'dart:typed_data';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/AdditionalFeaturesScreen/AboutAppScreen.dart';
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
  List<StoreModel> favoriteStores = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStores();
  }

  void _loadFavoriteStores() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500)); // Simulasi delay

    final filtered = widget.allStores
        .where((store) => widget.favoriteStoreIds.contains(store.id))
        .toList();

    setState(() {
      favoriteStores = filtered;
      isLoading = false;
    });
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String.split(',').last);
    } catch (e) {
      return null;
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst); // Balik ke Home
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllStoresScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AboutAppScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(Icons.favorite, color: Colors.red),
        ),
        title: const Text(
          'Favorite Store',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.white,
            shadows: [
              Shadow(offset: Offset(2.0, 2.0), blurRadius: 3.0, color: Colors.black45),
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.favorite, color: Colors.red),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.store_sharp), label: "Store"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"),
          BottomNavigationBarItem(icon: Icon(Icons.contact_mail), label: "Kontak"),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 16),
            Text(
              "Memuat toko favorit...",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text("Tunggu sebentar atau coba lagi nanti.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : favoriteStores.isEmpty
          ? const Center(child: Text("Belum ada toko favorit."))
          : ListView.builder(
        itemCount: favoriteStores.length,
        itemBuilder: (context, index) {
          final store = favoriteStores[index];
          final imageBytes = decodeBase64Image(store.imageBase64);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StoreDetailScreen(store: store),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageBytes != null
                          ? Image.memory(imageBytes, width: 80, height: 80, fit: BoxFit.cover)
                          : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.store, size: 40),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            store.description ?? 'Tidak ada deskripsi.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
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
