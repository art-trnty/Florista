import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  late String originalEmail;
  bool isEmailChanged = false;

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
    originalEmail = widget.currentData['email'];
    emailController.addListener(() {
      final currentEmail = emailController.text.trim();
      setState(() {
        isEmailChanged = currentEmail != originalEmail;
      });
    });
  }

  Future<String?> _promptPassword() async {
    String? password;
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Konfirmasi Password'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  password = controller.text.trim();
                  Navigator.pop(context);
                },
                child: const Text('Lanjut'),
              ),
            ],
          ),
    );
    return password;
  }

  Future<void> _sendEmailVerificationCode() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        final password = await _promptPassword();
        if (password == null || password.isEmpty) return;

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kode verifikasi telah dikirim ke email baru'),
          ),
        );
      } else {
        _showError('User tidak ditemukan.');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError('Password salah.');
      } else {
        _showError('Gagal mengirim verifikasi: ${e.message}');
      }
    } catch (e) {
      _showError('Gagal mengirim verifikasi: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      try {
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
        _showError('Gagal menyimpan: $e');
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
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
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
            child: Icon(Icons.person_outline, color: Colors.white),
          ),
        ],
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
                      const SizedBox(height: 8),
                      const Text(
                        'Informasi Dasar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),

                      _buildTextField(
                        nameController,
                        'Nama Lengkap',
                        icon: Icons.person,
                      ),
                      _buildTextField(
                        usernameController,
                        'Username',
                        icon: Icons.alternate_email,
                      ),

                      _buildTextField(
                        emailController,
                        'Email',
                        keyboardType: TextInputType.emailAddress,
                        icon: Icons.email,
                      ),
                      if (isEmailChanged) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ElevatedButton.icon(
                            onPressed: _sendEmailVerificationCode,
                            icon: const Icon(
                              Icons.verified,
                              color: Colors.lightBlue,
                            ),
                            label: const Text(
                              'Kirim Kode Verifikasi Email',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildTextField(
                        phoneController,
                        'Nomor Telepon',
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone,
                      ),
                      _buildTextField(
                        addressController,
                        'Alamat',
                        icon: Icons.home,
                      ),
                      _buildDropdown(
                        'Jenis Kelamin',
                        ['Laki-laki', 'Perempuan'],
                        gender,
                        (val) => setState(() => gender = val!),
                      ),

                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
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
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon) : null,
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
          validator:
              (value) =>
                  value == null || value.isEmpty ? 'Tidak boleh kosong' : null,
        ),
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: currentValue,
          items:
              items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.wc),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[100],
          ),
        ),
      ),
    );
  }
}
