import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:florista/screens/SignInScreen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String? _selectedGender;
  String? _selectedRole;
  int? _generatedOtp;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _roles = ['Pengguna', 'Admin'];

  Future<bool> _isUsernameExists(String username) async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();

    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _sendOtp(String email) async {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    _generatedOtp = random;
    print("Kode OTP untuk $email: $_generatedOtp");

    await _showOtpDialog(email);
  }

  Future<void> _showOtpDialog(String email) async {
    final otpController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Email'),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Masukkan Kode OTP'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (otpController.text == _generatedOtp.toString()) {
                  Navigator.of(context).pop();
                  await _createFirebaseAccount();
                } else {
                  _showErrorMessage('Kode OTP salah!');
                }
              },
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFirebaseAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final address = _addressController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final gender = _selectedGender ?? '';
    final role = _selectedRole ?? '';

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          'username': username,
          'address': address,
          'phoneNumber': phoneNumber,
          'gender': gender,
          'role': role,
          'email': email,
        });

        _showSuccessMessage('Akun berhasil diverifikasi dan terdaftar!');
      }
    } on FirebaseAuthException catch (error) {
      _showErrorMessage(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showErrorMessage('Terjadi kesalahan: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.greenAccent, Colors.lightGreen],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Background image overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/backgroundSign-Up.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Form content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Registrasi',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        RichText(
                          text: TextSpan(
                            text: "Sudah punya akun? ",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            children: [
                              TextSpan(
                                text: "Masuk disini",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const SignInScreen(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            hintText: 'Masukkan namamu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            hintText: 'Masukkan username-mu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_circle),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            hintText: 'Masukkan alamatmu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat tidak boleh kosong';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: 'Masukkan nomor HP mu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor HP tidak boleh kosong';
                            }
                            if (!RegExp(r'^\d{10,13}$').hasMatch(value)) {
                              return 'Masukkan nomor HP yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            hintText: 'Pilih jenis kelamin',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wc),
                          ),
                          items:
                              _genders
                                  .map(
                                    (gender) => DropdownMenuItem(
                                      value: gender,
                                      child: Text(gender),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedGender = value;
                            });
                          },
                          validator:
                              (value) =>
                                  value == null ? 'Pilih jenis kelamin' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            hintText: 'Pilih peran',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.work),
                          ),
                          items:
                              _roles
                                  .map(
                                    (role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                          validator:
                              (value) => value == null ? 'Pilih peran' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Masukkan alamat emailmu',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email tidak boleh kosong';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Masukkan email yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Masukkan kata sandimu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password tidak boleh kosong';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            hintText: 'Konfirmasi kata sandimu',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !_isConfirmPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Konfirmasi password tidak boleh kosong';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Registrasi',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color:
                                            Colors
                                                .white, // warna teks diubah menjadi putih
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final address = _addressController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final gender = _selectedGender ?? '';
    final role = _selectedRole ?? '';
    bool exists = await _isUsernameExists(username);

    if (exists) {
      _showErrorMessage(
        'Username sudah digunakan. Silakan pilih username lain.',
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _showEmailVerificationDialog(user);
        await user.reload(); // Refresh status user
        if (FirebaseAuth.instance.currentUser!.emailVerified) {
          // Jika terverifikasi, simpan ke Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': name,
                'username': username,
                'address': address,
                'phoneNumber': phoneNumber,
                'gender': gender,
                'role': role,
                'email': email,
              });
          _showSuccessMessage(
            'Email terverifikasi. Akun berhasil didaftarkan!',
          );
        } else {
          await user.delete();
          _showErrorMessage('Email belum diverifikasi. Akun tidak dibuat.');
        }
      }
    } on FirebaseAuthException catch (error) {
      _showErrorMessage(_getAuthErrorMessage(error.code));
    } catch (error) {
      _showErrorMessage('Terjadi kesalahan: $error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEmailVerificationDialog(User user) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verifikasi Email'),
          content: const Text(
            'Email verifikasi telah dikirim. Silakan cek email Anda dan klik link verifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await user.reload(); // reload status verifikasi
                if (FirebaseAuth.instance.currentUser!.emailVerified) {
                  Navigator.of(context).pop();
                } else {
                  _showErrorMessage(
                    'Email belum diverifikasi. Coba lagi setelah memverifikasi.',
                  );
                }
              },
              child: const Text('Sudah Verifikasi'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password terlalu lemah.';
      case 'email-already-in-use':
        return 'Akun dengan email tersebut sudah terdaftar.';
      case 'invalid-email':
        return 'Email tidak valid.';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi.';
    }
  }
}
