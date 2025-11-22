import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newEmail = '';
  bool _loading = false;

  Future<void> _changeEmail() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _currentPassword);
      await user.reauthenticateWithCredential(cred);

      // Update Firebase Auth email
      

      // Update Firestore admins collection
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).update({
        'email': _newEmail,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Email changed")));
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
      appBar: AppBar(
          title: Text('Change Email', style: GoogleFonts.poppins()),
          backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'New Email'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter valid email' : null,
                onSaved: (v) => _newEmail = v ?? '',
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter password' : null,
                onSaved: (v) => _currentPassword = v ?? '',
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changeEmail,
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      child: Text('Change Email', style: GoogleFonts.poppins()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
