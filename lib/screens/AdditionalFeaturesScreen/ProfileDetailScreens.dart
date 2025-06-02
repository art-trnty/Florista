import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:florista/screens/SignInScreen.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  _ProfileDetailScreenState createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool _isLoading = false;

  final user = FirebaseAuth.instance.currentUser;
  late final DocumentReference userDocRef;
  String? photoBase64;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid);
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: source);

    if (pickedImage != null) {
      setState(() => _isLoading = true);

      final bytes = await pickedImage.readAsBytes();
      final base64Image = base64Encode(bytes);

      try {
        await userDocRef.update({'photoBase64': base64Image});
        setState(() {
          photoBase64 = base64Image;
        });
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
    } else {
      print('No image selected.');
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
        MaterialPageRoute(builder: (context) => const SignInScreen()),
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
        title: const Text('Profil Saya'),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
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
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Data profil tidak ditemukan.'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final name = data['name'] ?? '-';
            final firstInitial = name.isNotEmpty ? name[0].toUpperCase() : '-';

            photoBase64 = data['photoBase64'];
            final imageProvider =
                (photoBase64 != null && photoBase64!.isNotEmpty)
                    ? _getProfileImageProvider(photoBase64!)
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
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.green),
                        onPressed: _changeProfileImage,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileItem(
                    Icons.account_circle,
                    'Username',
                    data['username'] ?? '-',
                  ),
                  _buildProfileItem(Icons.email, 'Email', data['email'] ?? '-'),
                  _buildProfileItem(
                    Icons.phone,
                    'Nomor Telepon',
                    data['phoneNumber'] ?? '-',
                  ),
                  _buildProfileItem(
                    Icons.location_on,
                    'Alamat',
                    data['address'] ?? '-',
                  ),
                  _buildProfileItem(
                    Icons.wc,
                    'Jenis Kelamin',
                    data['gender'] ?? '-',
                  ),
                  _buildProfileItem(Icons.badge, 'Role', data['role'] ?? '-'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
