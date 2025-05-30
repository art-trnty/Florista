import 'dart:convert';
import 'dart:io';

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
  final user = FirebaseAuth.instance.currentUser;
  late final DocumentReference userDocRef;
  String? photoBase64;

  @override
  void initState() {
    super.initState();
    userDocRef = FirebaseFirestore.instance.collection('users').doc(user!.uid);
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final doc = await userDocRef.get();
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      photoBase64 = data['photoBase64'];
    });
  }

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      final bytes = await File(pickedImage.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await userDocRef.update({'photoBase64': base64Image});

      setState(() {
        photoBase64 = base64Image;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Data profil tidak ditemukan.'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

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
                        backgroundImage:
                            photoBase64 != null
                                ? MemoryImage(base64Decode(photoBase64!))
                                : null,
                        child:
                            (photoBase64 == null)
                                ? Text(
                                  data['name'] != null &&
                                          data['name'].isNotEmpty
                                      ? data['name'][0].toUpperCase()
                                      : '-',
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
                    data['name'] ?? '-',
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
