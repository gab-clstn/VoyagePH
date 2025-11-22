// add_admin_screen.dart

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

  // -------------------------------------------------------
  // CREATE ADMIN IN FIREBASE AUTH + SAVE TO FIRESTORE
  // -------------------------------------------------------
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
      // Create Firebase Auth user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      final uid = userCredential.user!.uid;

      // SAVE ADMIN INFO TO COLLECTION: "admins"
      await FirebaseFirestore.instance.collection('admins').doc(uid).set({
        'firstName': _firstName,
        'lastName': _lastName,
        'email': _email,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Admin successfully added")));
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? "Auth error")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Admin", style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "First Name"),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter first name" : null,
                  onSaved: (v) => _firstName = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Last Name"),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Enter last name" : null,
                  onSaved: (v) => _lastName = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) => (v == null || !v.contains("@"))
                      ? "Enter valid email"
                      : null,
                  onSaved: (v) => _email = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 6)
                      ? "Minimum 6 characters"
                      : null,
                  onSaved: (v) => _password = v ?? '',
                ),
                TextFormField(
                  decoration:
                      const InputDecoration(labelText: "Retype Password"),
                  obscureText: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? "Retype password" : null,
                  onSaved: (v) => _retypePassword = v ?? '',
                ),
                const SizedBox(height: 20),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _addAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 40),
                        ),
                        child: Text("Add Admin",
                            style: GoogleFonts.poppins(
                                color: Colors.white, fontSize: 16)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
