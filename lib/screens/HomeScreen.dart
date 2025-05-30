import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/ProductModel.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/AllStoreScreen.dart';
import 'package:florista/screens/Product/StoreDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:florista/screens/ProfileDetailScreens.dart';
import 'package:florista/services/location_service.dart';
import 'package:florista/services/auth_service.dart';
import 'package:florista/widgets/ProductCard.dart';
import 'package:florista/widgets/StoreCard.dart';
import 'package:florista/AddPostScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _address = "Memuat lokasi...";
  bool _isAdmin = false;
  String? _currentUserUid;
  String _profileImageUrl = "";
  List<ProductModel> _products = [];
  List<StoreModel> _stores = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _checkAdminStatus();
    _loadProfileImage();
    _loadCurrentUserUid();
    _fetchStores();
    _fetchAllProducts();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllStoresScreen()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
      );
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadCurrentUserUid() {
    setState(() {
      _currentUserUid = AuthService.currentUserUid;
    });
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

  Future<void> _fetchAllProducts() async {
    final storeSnapshots =
        await FirebaseFirestore.instance.collection('stores').get();
    for (var storeDoc in storeSnapshots.docs) {
      final productsSnapshot =
          await storeDoc.reference.collection('products').get();
      for (var productDoc in productsSnapshot.docs) {
        final data = productDoc.data();
        print("✅ Found Product in ${storeDoc.id}: $data");
      }
    }
  }

  Future<void> _loadLocation() async {
    String result = await LocationService.getCurrentAddress();
    setState(() {
      _address = result;
    });
  }

  Future<void> _checkAdminStatus() async {
    bool result = await AuthService.checkIfAdmin();
    setState(() {
      _isAdmin = result;
    });
  }

  Future<void> _loadProfileImage() async {
    String imageUrl = await AuthService.getProfilePicture();
    setState(() {
      _profileImageUrl = imageUrl.isNotEmpty ? imageUrl : "assets/profile.jpg";
    });
  }

  void _addNewStore() async {
    if (_isAdmin) {
      final result = await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AddPostScreen()));
      if (result == true) {
        _fetchStores();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Hanya admin yang bisa menambahkan toko!"),
        ),
      );
    }
  }

  Future<void> _deleteStore(String storeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Toko berhasil dihapus.")));
      _fetchStores();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menghapus toko: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton:
          _isAdmin
              ? FloatingActionButton(
                backgroundColor: Colors.green,
                onPressed: _addNewStore,
                child: const Icon(Icons.add),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Toko"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _address,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset(
                      'assets/Additional/Flowers.jpg',
                      width: 190,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Selamat datang di aplikasi Toko Tanaman Hias kami! Di sini, Anda dapat menemukan berbagai toko yang menjual tanaman hias terbaik di kota. Temukan rekomendasi toko favorit Anda dan buat taman Anda lebih indah.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ],
              ),

              // Konten scrollable
              SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.green),
                          border: InputBorder.none,
                          hintText: "Cari Toko tanaman hias terdekat...",
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Daftar Toko Tanaman Hias",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllStoresScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child:
                          _stores.isEmpty
                              ? const Center(child: Text("Belum ada toko."))
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _stores.length,
                                itemBuilder: (context, index) {
                                  final store = _stores[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder:
                                              (context) => StoreDetailScreen(
                                                store: store,
                                              ),
                                        ),
                                      );
                                    },
                                    child: StoreCard(
                                      store: store,
                                      currentUserUid: _currentUserUid,
                                      onDelete: () => _deleteStore(store.id),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
