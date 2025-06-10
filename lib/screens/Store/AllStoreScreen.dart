import 'package:florista/screens/HomeScreen.dart';
import 'package:florista/screens/Store/EditStoreScreen.dart';
import 'package:florista/screens/Store/FavoriteStoreScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/widgets/StoreCard.dart';
import 'package:florista/services/auth_service.dart';

import '../AdditionalFeaturesScreen/AboutAppScreen.dart' show AboutAppScreen;

class AllStoresScreen extends StatefulWidget {
  const AllStoresScreen({super.key});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen>
    with SingleTickerProviderStateMixin {
  List<StoreModel> _stores = [];
  Set<String> _favoriteStoreIds = {};
  String? _currentUserUid;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentUserUid = AuthService.currentUserUid;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchStores();
    _fetchFavoriteStores();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    _animationController.forward();
  }

  Future<void> _fetchFavoriteStores() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserUid)
            .get();

    final List<dynamic> favoriteIds = userDoc.data()?['favoriteStoreIds'] ?? [];
    setState(() {
      _favoriteStoreIds = favoriteIds.cast<String>().toSet();
    });
  }

  Future<void> _toggleFavorite(String storeId) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserUid);
    final isFavorite = _favoriteStoreIds.contains(storeId);

    await userRef.update({
      'favoriteStoreIds':
          isFavorite
              ? FieldValue.arrayRemove([storeId])
              : FieldValue.arrayUnion([storeId]),
    });

    setState(() {
      if (isFavorite) {
        _favoriteStoreIds.remove(storeId);
      } else {
        _favoriteStoreIds.add(storeId);
      }
    });
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

  void _showStoreSelectionDialog() {
    final adminStores =
        _stores.where((store) => store.owner == _currentUserUid).toList();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pilih Toko untuk Diedit"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: adminStores.length,
              itemBuilder: (context, index) {
                final store = adminStores[index];
                return ListTile(
                  leading: const Icon(Icons.store),
                  title: Text(store.name),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStoreScreen(store: store),
                      ),
                    );
                    _fetchStores();
                  },
                );
              },
            ),
          ),
        );
      },
    );
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
          child: Icon(Icons.store_outlined, color: Colors.white),
        ),
        title: const Text(
          'All Store',
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.store_outlined, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffE6F9E6), Color(0xffFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            _stores.isEmpty
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        "Memuat data toko...",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tunggu sebentar atau coba lagi nanti.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                : Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: _stores.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          mainAxisExtent: 210,
                        ),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
                      final isFavorite = _favoriteStoreIds.contains(store.id);
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            0.1 * index,
                            1.0,
                            curve: Curves.easeIn,
                          ),
                        ),
                        child: StoreCard(
                          store: store,
                          currentUserUid: _currentUserUid,
                          onDelete: () => _deleteStore(store.id),
                          isFavorite: isFavorite,
                          onToggleFavorite: () => _toggleFavorite(store.id),
                        ),
                      );
                    },
                  ),
                ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) async {
          switch (index) {
            case 0:
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
              break;
            case 1:
              break;
            case 2:
              if (_currentUserUid != null) {
                final userDoc =
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUserUid)
                        .get();
                final List<dynamic> favoriteIds =
                    userDoc.data()?['favoriteStoreIds'] ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FavoriteStoreScreen(
                          favoriteStoreIds: favoriteIds.cast<String>(),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutAppScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_sharp),
            label: "Store",
          ),
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
    );
  }
}
