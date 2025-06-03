import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  final String storeId;
  final String ownerId;

  const AddProductScreen({
    super.key,
    required this.storeId,
    required this.ownerId,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isLoading = false;

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

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() || _base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data dan gambar produk")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('products').add({
        'storeId': widget.storeId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageBase64': _base64Image!,
        'owner': widget.ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal menambahkan produk: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Produk"),
        backgroundColor: Colors.green,
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
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                    image:
                        _imageBytes != null
                            ? DecorationImage(
                              image: MemoryImage(_imageBytes!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),
                  child:
                      _imageBytes == null
                          ? const Center(
                            child: Icon(Icons.add_photo_alternate, size: 40),
                          )
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 16),
              _buildTextField("Nama Produk", _nameController),
              _buildTextField("Deskripsi", _descController, maxLines: 2),
              _buildTextField(
                "Harga",
                _priceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                    onPressed: _submitProduct,
                    icon: const Icon(Icons.save),
                    label: const Text("Simpan Produk"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
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
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? "$label tidak boleh kosong"
                    : null,
      ),
    );
  }
}
