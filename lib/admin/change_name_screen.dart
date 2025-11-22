import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangeNameScreen extends StatefulWidget {
  const ChangeNameScreen({super.key});

  @override
  State<ChangeNameScreen> createState() => _ChangeNameScreenState();
}

class _ChangeNameScreenState extends State<ChangeNameScreen> {
  final _formKey = GlobalKey<FormState>();
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _loading = false;

  Future<void> _changeName() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _password,
      );
      await user.reauthenticateWithCredential(cred);

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .update({
        'firstName': _firstName,
        'lastName': _lastName,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Name updated")));
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
          title: Text('Change Name', style: GoogleFonts.poppins()),
          backgroundColor: primary),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter first name' : null,
                onSaved: (v) => _firstName = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter last name' : null,
                onSaved: (v) => _lastName = v ?? '',
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter password' : null,
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _changeName,
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      child: Text('Change Name', style: GoogleFonts.poppins()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
