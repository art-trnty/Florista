import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentData;
  final DocumentReference userDocRef;

  const EditProfileScreen({
    super.key,
    required this.currentData,
    required this.userDocRef,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  String gender = 'Laki-laki';
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final rawGender = widget.currentData['gender'] ?? 'Laki-laki';
    final genderList = ['Laki-laki', 'Perempuan'];
    gender = genderList.contains(rawGender) ? rawGender : 'Laki-laki';

    nameController = TextEditingController(text: widget.currentData['name']);
    usernameController = TextEditingController(
      text: widget.currentData['username'],
    );
    emailController = TextEditingController(text: widget.currentData['email']);
    phoneController = TextEditingController(
      text: widget.currentData['phoneNumber'],
    );
    addressController = TextEditingController(
      text: widget.currentData['address'],
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
        // Ambil semua dokumen user dari koleksi (misal: 'users')
        final snapshot =
            await FirebaseFirestore.instance.collection('users').get();

        final newUsername = usernameController.text.trim();
        final newEmail = emailController.text.trim();
        final newPhone = phoneController.text.trim();

        bool isDuplicate(String field, String value) {
          return snapshot.docs.any(
            (doc) => doc.id != widget.userDocRef.id && doc.get(field) == value,
          );
        }

        if (isDuplicate('username', newUsername)) {
          _showError('Username sudah digunakan.');
        } else if (isDuplicate('email', newEmail)) {
          _showError('Email sudah digunakan.');
        } else if (isDuplicate('phoneNumber', newPhone)) {
          _showError('Nomor telepon sudah digunakan.');
        } else {
          await widget.userDocRef.update({
            'name': nameController.text.trim(),
            'username': newUsername,
            'email': newEmail,
            'phoneNumber': newPhone,
            'address': addressController.text.trim(),
            'gender': gender,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil berhasil diperbarui')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      } finally {
        setState(() => isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.green,
      ),
      body:
          isSaving
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      _buildTextField(nameController, 'Nama Lengkap'),
                      _buildTextField(usernameController, 'Username'),
                      _buildTextField(
                        emailController,
                        'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _buildTextField(
                        phoneController,
                        'Nomor Telepon',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField(addressController, 'Alamat'),
                      _buildDropdown(
                        'Jenis Kelamin',
                        ['Laki-laki', 'Perempuan'],
                        gender,
                        (val) => setState(() => gender = val!),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Perubahan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? 'Tidak boleh kosong' : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String currentValue,
    void Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items:
            items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
