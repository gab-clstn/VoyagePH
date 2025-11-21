import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AddAdminScreen extends StatefulWidget {
  const AddAdminScreen({super.key});

  @override
  State<AddAdminScreen> createState() => _AddAdminScreenState();
}

class _AddAdminScreenState extends State<AddAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  String _retypePassword = '';
  bool _loading = false;

  Future<void> _addAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_password != _retypePassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email, password: _password);

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Admin added")));
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(title: Text('Add Admin', style: GoogleFonts.poppins()), backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter first name' : null,
                  onSaved: (v) => _firstName = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Enter last name' : null,
                  onSaved: (v) => _lastName = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                  onSaved: (v) => _email = v ?? '',
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                  onSaved: (v) => _password = v ?? '',
                ),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Retype Password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Retype password' : null,
                  onSaved: (v) => _retypePassword = v ?? '',
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addAdmin,
                        style: ElevatedButton.styleFrom(backgroundColor: primary),
                        child: Text('Add Admin', style: GoogleFonts.poppins()),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
