import 'package:flutter/material.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/FavoriteStoreScreen.dart';
import 'package:florista/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:florista/screens/HomeScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  bool _isLoading = true;
  int _selectedIndex = 3;
  String? _currentUserUid;
  List<String> favoriteStoreIds = [];
  List<StoreModel> _stores = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserUidAndData();
  }

  String _formatPhoneDisplay(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.startsWith('+62')) {
      clean = '0' + clean.substring(3);
    } else if (clean.startsWith('62')) {
      clean = '0' + clean.substring(2);
    }

    List<String> parts = [];
    for (int i = 0; i < clean.length; i += 4) {
      int end = (i + 4 < clean.length) ? i + 4 : clean.length;
      parts.add(clean.substring(i, end));
    }

    return parts.join('-');
  }

  Future<void> _loadCurrentUserUidAndData() async {
    final uid = AuthService.currentUserUid;
    if (uid != null) {
      setState(() {
        _currentUserUid = uid;
      });
      await Future.wait([_loadFavoriteStores(uid), _fetchStores()]);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadFavoriteStores(String uid) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
        break;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget buildContactCard({
    required String name,
    required String phone,
    required String instagram,
    required String facebook,
    required String email,
    required String address,
    required String imagePath,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap:
                            () => _launchURL(
                              'https://wa.me/${phone.replaceAll('+', '').replaceAll(' ', '')}',
                            ),
                        child: Text(
                          "📞 WhatsApp: ${_formatPhoneDisplay(phone)}",
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                      _buildContactLink(
                        label: "📷 Instagram: @$instagram",
                        url: 'https://instagram.com/$instagram',
                      ),
                      _buildContactLink(
                        label: "📘 Facebook: $facebook",
                        url: 'https://facebook.com/$facebook',
                      ),
                      _buildContactLink(
                        label: "✉️ Email: $email",
                        url: 'mailto:$email',
                      ),
                      _buildContactLink(
                        label: "📍 $address",
                        url:
                            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage(imagePath),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String text, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: GestureDetector(
        onTap: () => _launchURL(url),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: Colors.grey[800]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Colors.blue),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactLink({required String label, required String url}) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: const TextStyle(color: Colors.blue, fontSize: 13),
        ),
      ),
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
          child: Icon(Icons.contact_page_outlined, color: Colors.white),
        ),
        title: const Text(
          'About',
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
            child: Icon(Icons.contact_support_rounded, color: Colors.white),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SizedBox(height: 5),
                      Image.asset(
                        'assets/Additional/backgroundAboutApp.png',
                        height:
                            MediaQuery.of(context).size.height *
                            0.3, // Lebih proporsional
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text(
                                '- Florista -',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aplikasi ini dibuat untuk membantu Anda menemukan berbagai toko tanaman hias terbaik di sekitar Anda. Dengan antarmuka yang sederhana dan fitur-fitur yang lengkap, Anda bisa mencari, menambahkan favorit, dan mengeksplor berbagai tanaman hias dengan mudah.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              const Center(
                                child: Text(
                                  'Kontak Person',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              buildContactCard(
                                name: "Person 1 - Rara Ananta Bunga",
                                phone: "+62 89603788974",
                                instagram: "art.trnty",
                                facebook: "art.trnty",
                                email: "rara.anantabunga03@gmail.com",
                                address: "Jl. H Sanusi No.3231, Suka Bangun",
                                imagePath: "assets/Additional/art.trnty.jpeg",
                              ),
                              buildContactCard(
                                name: "Person 2 - Revina Trisna Aini",
                                phone: "+62 83178355461",
                                instagram: "cacicillo",
                                facebook: "revina.trisnaaini.9",
                                email: "trisnaainirevina@gmail.com",
                                address: "Jln. Mayor zen, Kota Palembang",
                                imagePath: "assets/Additional/Revina.jpg",
                              ),
                              buildContactCard(
                                name: "Person 3 - Komariah Wulandari",
                                phone: "+62 82387249538",
                                instagram: "w_lann1",
                                facebook: "komariah.wulandari.7",
                                email:
                                    "komariahwulandari_2226240119@mhs.mdp.ac.id",
                                address: "Jl. Perintis Kemerdekaan, Palembang",
                                imagePath: "assets/Additional/wulann.jpg",
                              ),
                              buildContactCard(
                                name: "Person 4 - Nabila Salwa Zahrani",
                                phone: "+62 82298203736",
                                instagram: "nabilaaasz__",
                                facebook: "nabila.salwazahrani",
                                email:
                                    "nabilasalwazahrani_2226240133@mhs.mdp.ac.id",
                                address: "Jl. Gersik, Kota Palembang, ",
                                imagePath: "assets/Additional/nabila.jpg",
                              ),

                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text(
                                'Dikembangkan oleh Tim Florista.\n© 2025 Florista Inc.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
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
