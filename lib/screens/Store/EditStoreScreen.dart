import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/models/StoreModel.dart';

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store.name);
    _descriptionController = TextEditingController(
      text: widget.store.description,
    );
    _addressController = TextEditingController(text: widget.store.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
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
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toko berhasil diperbarui.')),
      );

      Navigator.pop(context);
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
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Alamat tidak boleh kosong'
                            : null,
              ),
              const SizedBox(height: 24),
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
