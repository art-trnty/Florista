import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:florista/screens/AdditionalFeaturesScreen/AboutAppScreen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:florista/screens/AdditionalFeaturesScreen/EditProfileScreen.dart';
import 'package:florista/screens/SignInScreen.dart';
import 'package:florista/screens/Store/AllStoreScreen.dart';
import 'package:florista/screens/Store/FavoriteStoreScreen.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;
  late final DocumentReference userDocRef;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);
      _fetchUserData();
    }
  }

  void _fetchUserData() async {
    setState(() => _isLoading = true);
    final snapshot = await userDocRef.get();
    setState(() {
      userData = snapshot.data() as Map<String, dynamic>;
      _isLoading = false;
    });
  }

  ImageProvider<Object> _getProfileImageProvider(String imageData) {
    try {
      final base64Str =
          imageData.contains(',') ? imageData.split(',').last : imageData;
      return MemoryImage(base64Decode(base64Str));
    } catch (e) {
      debugPrint("Gagal decode base64: $e");
      return const AssetImage("assets/profile.jpg");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() => _isLoading = true);
      final bytes = await pickedImage.readAsBytes();
      final base64Image = base64Encode(bytes);

      try {
        await userDocRef.update({'photoBase64': base64Image});
        setState(() {}); // reload
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto berhasil diperbarui')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan foto: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changeProfileImage() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Pengguna belum login.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Icon back putih
        title: const Text(
          'Profile',
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
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildProfileContent(),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: SpinKitFadingCircle(color: Colors.green, size: 60.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.green.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: userDocRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return const Center(child: SizedBox.shrink());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data profil tidak ditemukan.'));
          }

          userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData!['name'] ?? '-';
          final firstInitial = name.isNotEmpty ? name[0].toUpperCase() : '-';
          final photoBase64 = userData!['photoBase64'] ?? '';
          final imageProvider =
              photoBase64.isNotEmpty
                  ? _getProfileImageProvider(photoBase64)
                  : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.green.shade100,
                      backgroundImage: imageProvider,
                      child:
                          imageProvider == null
                              ? Text(
                                firstInitial,
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _changeProfileImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildProfileItem(
                  Icons.account_circle,
                  'Username',
                  userData!['username'] ?? '-',
                ),
                _buildProfileItem(
                  Icons.email,
                  'Email',
                  userData!['email'] ?? '-',
                ),
                _buildProfileItem(
                  Icons.phone,
                  'Nomor Telepon',
                  userData!['phoneNumber'] ?? '-',
                ),
                _buildProfileItem(
                  Icons.location_on,
                  'Alamat',
                  userData!['address'] ?? '-',
                ),
                _buildProfileItem(
                  Icons.wc,
                  'Jenis Kelamin',
                  userData!['gender'] ?? '-',
                ),
                _buildProfileItem(
                  Icons.badge,
                  'Role',
                  userData!['role'] ?? '-',
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditProfileScreen(
                              currentData: userData!,
                              userDocRef: userDocRef,
                            ),
                      ),
                    );

                    if (shouldRefresh == true) _fetchUserData();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
