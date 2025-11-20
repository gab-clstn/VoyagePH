import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(title: Text('Users', style: GoogleFonts.poppins()), backgroundColor: primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No users found'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.white,
                title: Text(data['displayName'] ?? data['email'] ?? 'User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(data['email'] ?? '-', style: GoogleFonts.poppins()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Remove user document?', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: GoogleFonts.poppins())),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text('Remove', style: GoogleFonts.poppins())),
                        ],
                      ),
                    );
                    if (confirm == true) await d.reference.delete();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}