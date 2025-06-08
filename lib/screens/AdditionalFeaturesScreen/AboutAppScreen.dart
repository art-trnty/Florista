import 'package:flutter/material.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/FavoriteStoreScreen.dart';
import 'package:florista/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/AdditionalFeaturesScreen/AboutAppScreen.dart'; // Untuk navigasi ulang bila perlu
import 'package:florista/screens/HomeScreen.dart'; // Tambahkan jika perlu kembali ke Home

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  int _selectedIndex = 3;
  String? _currentUserUid;
  List<String> favoriteStoreIds = [];
  List<StoreModel> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserUid();
    _fetchStores();
    _loadFavoriteStores();
  }

  void _loadCurrentUserUid() {
    final uid = AuthService.currentUserUid;
    setState(() {
      _currentUserUid = uid;
    });
  }

  Future<void> _loadFavoriteStores() async {
    if (_currentUserUid == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserUid)
              .get();
      final data = snapshot.data();
      if (data != null && data.containsKey('favoriteStores')) {
        setState(() {
          favoriteStoreIds = List<String>.from(data['favoriteStores']);
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat toko favorit: $e");
    }
  }

  Future<void> _fetchStores() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('stores').get();
    setState(() {
      _stores =
          snapshot.docs
              .map((doc) => StoreModel.fromMap(doc.data(), doc.id))
              .toList();
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllStoresScreen()),
        );
        break;
      case 2:
        if (_currentUserUid != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => FavoriteStoreScreen(
                    favoriteStoreIds: favoriteStoreIds,
                    allStores: _stores,
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Data pengguna belum dimuat.")),
          );
        }
        break;
      case 3:
        // Sudah di halaman ini
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, // <-- Tambahkan baris ini
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
            label: "Favorite Store",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: "Kontak",
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Florista - Aplikasi Toko Tanaman Hias',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Aplikasi ini dibuat untuk membantu Anda menemukan berbagai toko tanaman hias terbaik di sekitar Anda. Dengan antarmuka yang sederhana dan fitur-fitur yang lengkap, Anda bisa mencari, menambahkan favorit, dan mengeksplor berbagai tanaman hias dengan mudah.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Dikembangkan oleh Tim Florista.\n© 2025 Florista Inc.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
