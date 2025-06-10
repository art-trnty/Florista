import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:florista/models/StoreModel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditStoreScreen extends StatefulWidget {
  final StoreModel store;

  const EditStoreScreen({super.key, required this.store});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _ratingController;

  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _descriptionController = TextEditingController(
      text: widget.store.description,
    );
    _addressController = TextEditingController(text: widget.store.address);
    _emailController = TextEditingController(text: widget.store.email ?? '');
    _phoneController = TextEditingController(text: widget.store.phone ?? '');
    _imageBase64 = widget.store.imageBase64;
    _ratingController = TextEditingController(
      text: widget.store.rating?.toString() ?? '0.0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.store.id)
            .update({'imageBase64': base64Image});
        setState(() {
          _imageBase64 = base64Image;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto toko berhasil diperbarui.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan lokasi tidak aktif')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}";
        setState(() {
          _addressController.text = address;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Alamat berhasil diisi')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan alamat: $e')));
    }
  }

  Future<void> _updateStore() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.store.id)
          .update({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'address': _addressController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'imageBase64': _imageBase64,
            'rating': double.tryParse(_ratingController.text.trim()) ?? 0.0,
          });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memperbarui toko: $e')));
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Toko'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffE6F9E6), Color(0xffFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        _imageBase64 != null
                            ? Image.memory(
                              base64Decode(_imageBase64!),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              height: 160,
                              alignment: Alignment.center,
                              child: const CircularProgressIndicator(),
                            ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Ubah Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Toko'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Nama toko tidak boleh kosong'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Deskripsi tidak boleh kosong'
                            : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Gunakan lokasi saat ini',
                  ),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Alamat tidak boleh kosong'
                            : null,
              ),

              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Toko'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor HP Toko'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor HP tidak boleh kosong';
                  }
                  final phoneRegex = RegExp(r'^08\d{8,12}$');
                  if (!phoneRegex.hasMatch(value)) {
                    return 'Nomor HP harus terdiri dari 10-13 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating Toko '),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final rating = double.tryParse(value ?? '');
                  if (rating == null || rating < 0 || rating > 5) {
                    return 'Rating harus antara 0.0 dan 5.0';
                  }
                  return null;
                },
              ),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateStore,
                icon: const Icon(Icons.save),
                label:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Simpan Perubahan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
