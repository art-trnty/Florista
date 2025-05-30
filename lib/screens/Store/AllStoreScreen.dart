import 'package:florista/screens/Store/EditStoreScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/widgets/StoreCard.dart';
import 'package:florista/services/auth_service.dart';

class AllStoresScreen extends StatefulWidget {
  const AllStoresScreen({super.key});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen>
    with SingleTickerProviderStateMixin {
  List<StoreModel> _stores = [];
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
                    Navigator.of(context).pop(); // tutup dialog
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditStoreScreen(store: store),
                      ),
                    );
                    _fetchStores(); // ambil ulang data toko setelah kembali
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
        title: const Text("Semua Toko Tanaman Hias"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_stores.any((store) => store.owner == _currentUserUid))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showStoreSelectionDialog(),
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
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset("assets/empty_store.png", height: 160),
                      const SizedBox(height: 16),
                      const Text(
                        "Belum ada toko tersedia",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
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
                          childAspectRatio: 4 / 4,
                        ),
                    itemBuilder: (context, index) {
                      final store = _stores[index];
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
                        ),
                      );
                    },
                  ),
                ),
      ),
    );
  }
}
