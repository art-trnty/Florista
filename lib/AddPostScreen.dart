import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _base64Image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _pickLocation() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied ||
          hasPermission == LocationPermission.deniedForever) {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          throw 'Izin lokasi ditolak';
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final url =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';

      if (!await canLaunchUrlString(url))
        throw 'Tidak dapat membuka Google Maps';
      await launchUrlString(url);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka alamat: $e')));
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Layanan lokasi tidak aktif.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Izin lokasi ditolak.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Izin lokasi ditolak permanen.")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final address =
          "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}";
      setState(() => _addressController.text = address);
    }
  }

  Future<void> _submitStore() async {
    if (!_formKey.currentState!.validate() || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lengkapi semua data dan pilih gambar toko"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("User belum login")));
        return;
      }

      final storeData = {
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'imageBase64': _base64Image!,
        'owner': currentUser.uid,
        'createdAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('stores').add(storeData);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set({'store': storeData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toko berhasil ditambahkan!")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Terjadi kesalahan: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Icon back putih
        title: const Text(
          'Add Store',
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
            child: Icon(Icons.store_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child:
                      _imageBytes != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Center(
                            child: Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField("Nama Toko", _nameController),
              _buildTextFieldWithIcon(
                label: "Alamat",
                controller: _addressController,
                icon: Icons.my_location,
                onIconPressed: _getCurrentLocation,
              ),
              _buildTextField("Deskripsi", _descriptionController, maxLines: 3),
              _buildTextField(
                "Nomor Telepon",
                _phoneController,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                "Email",
                _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: _submitStore,
                    icon: const Icon(Icons.store),
                    label: const Text("Simpan Toko"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label tidak boleh kosong";
          }

          if (label == "Nomor Telepon") {
            final phoneRegExp = RegExp(r'^[0-9]{8,15}$');
            if (!phoneRegExp.hasMatch(value.trim())) {
              return "Nomor telepon tidak valid (hanya angka, 10-13 digit)";
            }
          }

          if (label == "Email") {
            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegExp.hasMatch(value.trim())) {
              return "Email tidak valid";
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _buildTextFieldWithIcon({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    VoidCallback? onIconPressed,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          suffixIcon:
              icon != null
                  ? IconButton(icon: Icon(icon), onPressed: onIconPressed)
                  : null,
        ),
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? "$label tidak boleh kosong"
                    : null,
      ),
    );
  }
}
