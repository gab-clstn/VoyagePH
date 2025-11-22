import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  bool _loading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New passwords do not match")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_newPassword);

      // Update password field in Firestore admins collection (optional)
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).update({
        'password': _newPassword, // if you store hashed passwords, hash it
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Password changed")));
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
          title: Text('Change Password', style: GoogleFonts.poppins()),
          backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter password' : null,
                onSaved: (v) => _currentPassword = v ?? '',
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 chars' : null,
                onSaved: (v) => _newPassword = v ?? '',
              ),
              TextFormField(
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm New Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Confirm new password' : null,
                onSaved: (v) => _confirmPassword = v ?? '',
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      child: Text('Change Password', style: GoogleFonts.poppins()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
