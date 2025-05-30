import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:florista/models/ProductModel.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/StoreDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:florista/screens/AdditionalFeaturesScreen/ProfileDetailScreens.dart';
import 'package:florista/services/location_service.dart';
import 'package:florista/services/auth_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";

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
    final filteredStores =
        _stores.where((store) {
          final name = store.name.toLowerCase();
          return name.contains(_searchKeyword);
        }).toList();

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Header dengan lokasi & foto profil
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 200,
                          child: Text(
                            _address,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _onItemTapped(3),
                      child: CircleAvatar(
                        backgroundImage:
                            _profileImageUrl.startsWith("http")
                                ? NetworkImage(_profileImageUrl)
                                : AssetImage(_profileImageUrl) as ImageProvider,
                        radius: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 🔹 Banner Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/Additional/Flowers.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Deskripsi Aplikasi
                const Text(
                  'Temukan Toko Tanaman Hias Favorit Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Aplikasi ini membantu Anda menemukan berbagai toko tanaman hias terbaik di kota. Jelajahi dan buat taman Anda lebih hidup!',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),

                const SizedBox(height: 24),

                // 🔹 Search Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchKeyword = value.toLowerCase();
                      });
                    },
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: Colors.green),
                      border: InputBorder.none,
                      hintText: "Cari toko tanaman hias...",
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Section Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Toko Tanaman Hias",
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

                // 🔹 Daftar toko (horizontal scroll)
                Expanded(
                  child:
                      _stores.isEmpty
                          ? Center(
                            child: CircularProgressIndicator(),
                          ) // contoh shimmer/loader
                          : filteredStores.isEmpty
                          ? const Center(
                            child: Text(
                              "Toko tidak ditemukan.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : GridView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: filteredStores.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.1,
                                ),
                            itemBuilder: (context, index) {
                              final store = filteredStores[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              StoreDetailScreen(store: store),
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
        ),
      ),
    );
  }
}
