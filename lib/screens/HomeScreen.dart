// Tambahkan ini di import
import 'dart:convert'; // untuk base64Decode
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/screens/Store/FavoriteStoreScreen.dart';
import 'package:flutter/material.dart';
import 'package:florista/models/ProductModel.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/StoreDetailScreen.dart';
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
  bool _isProfileLoading = true;
  String? _currentUserUid;
  String _profileImageUrl = "";
  List<ProductModel> _products = [];
  List<StoreModel> _stores = [];
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = "";
  List<String> favoriteStoreIds = [];

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _checkAdminStatus();
    _loadCurrentUserUid();
    _fetchStores();
    _fetchAllProducts();
    _loadFavoriteStores();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
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
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileDetailScreen()),
      ).then((_) {
        if (_currentUserUid != null) {
          _loadProfileImage(_currentUserUid!); // Refresh setelah kembali
        }
      });
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _loadCurrentUserUid() {
    final uid = AuthService.currentUserUid;
    setState(() {
      _currentUserUid = uid;
    });
    if (uid != null) {
      _loadProfileImage(uid);
    }
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

  void _loadProfileImage(String uid) async {
    setState(() {
      _isProfileLoading = true;
    });

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && data['photoBase64'] != null) {
        setState(() {
          _profileImageUrl = data['photoBase64'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile image: $e");
    } finally {
      setState(() {
        _isProfileLoading = false;
      });
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

  Future<void> _fetchAllProducts() async {
    final storeSnapshots =
        await FirebaseFirestore.instance.collection('stores').get();
    List<ProductModel> loadedProducts = [];

    for (var storeDoc in storeSnapshots.docs) {
      final productsSnapshot =
          await storeDoc.reference.collection('products').get();
      for (var productDoc in productsSnapshot.docs) {
        final data = productDoc.data();
        final product = ProductModel.fromMap(productDoc.id, data);
        loadedProducts.add(product);
      }
    }

    setState(() {
      _products = loadedProducts;
    });
  }

  Future<void> _loadLocation() async {
    try {
      String result = await LocationService.getCurrentAddress();
      setState(() {
        _address = result;
      });
    } catch (e) {
      setState(() {
        _address = "Gagal memuat lokasi";
      });
    }
  }

  static Future<void> toggleFavoriteStore(String userId, String storeId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    final List favorites = data?['favoriteStores'] ?? [];

    if (favorites.contains(storeId)) {
      favorites.remove(storeId);
    } else {
      favorites.add(storeId);
    }

    await userRef.update({'favoriteStores': favorites});
  }

  Future<void> _checkAdminStatus() async {
    bool result = await AuthService.checkIfAdmin();
    setState(() {
      _isAdmin = result;
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

  ImageProvider<Object> _getProfileImageProvider(String imageData) {
    try {
      if (imageData.startsWith("data:image") || imageData.length > 100) {
        final base64Str =
            imageData.contains(',') ? imageData.split(',').last : imageData;
        return MemoryImage(base64Decode(base64Str));
      }
    } catch (e) {
      debugPrint("Gagal decode base64: $e");
    }
    return const AssetImage("assets/profile.jpg");
  }

  @override
  Widget build(BuildContext context) {
    final filteredStores =
        _stores
            .where(
              (store) => store.name.toLowerCase().contains(
                _searchKeyword.toLowerCase(),
              ),
            )
            .toList();

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
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite Store",
          ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header lokasi + profil
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
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
                      child:
                          _isProfileLoading
                              ? Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                ),
                              )
                              : CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _getProfileImageProvider(
                                  _profileImageUrl,
                                ),
                              ),
                    ),
                  ],
                ),
              ),

              // Konten scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      _stores.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : filteredStores.isEmpty
                          ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                "Toko tidak ditemukan.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                          : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
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
                              final isFavorite = favoriteStoreIds.contains(
                                store.id,
                              );

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
                                  isFavorite: isFavorite,
                                  onToggleFavorite: () {
                                    setState(() {
                                      if (isFavorite) {
                                        favoriteStoreIds.remove(store.id);
                                      } else {
                                        favoriteStoreIds.add(store.id);
                                      }
                                    });
                                    if (_currentUserUid != null) {
                                      toggleFavoriteStore(
                                        _currentUserUid!,
                                        store.id,
                                      );
                                    }
                                  },
                                  onDelete: () => _deleteStore(store.id),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
