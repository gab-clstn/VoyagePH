import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key});

  // Replace with your real admin emails or fetch from secure source / custom claims.
  static const List<String> adminEmails = [
    'admin@voyageph.example',
    // add more admin emails
  ];

  Future<bool> _isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return adminEmails.contains(user.email);
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(title: Text('Admin Login', style: GoogleFonts.poppins()), backgroundColor: primary),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48), backgroundColor: primary),
            onPressed: () async {
              final ok = await _isAdmin();
              if (ok) {
                if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboard()));
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not authorized as admin.')));
                }
              }
            },
            child: Text('Continue as Admin (current user)', style: GoogleFonts.poppins()),
          ),
        ),
      ),
    );
  }
}