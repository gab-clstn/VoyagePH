import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<List<Map<String, dynamic>>> _getAllUsersAndAdmins() async {
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();
    final adminsSnap = await FirebaseFirestore.instance
        .collection('admins')
        .orderBy('createdAt', descending: true)
        .get();

    final users = usersSnap.docs
        .map((d) => {
              ...d.data(),
              'isAdmin': false,
              'docRef': d.reference,
            })
        .toList();

    final admins = adminsSnap.docs
        .map((d) => {
              ...d.data(),
              'isAdmin': true,
              'docRef': d.reference,
            })
        .toList();

    return [...users, ...admins];
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllUsersAndAdmins(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final combinedDocs = snap.data ?? [];

          if (combinedDocs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: combinedDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final data = combinedDocs[i];
              final displayName = data['displayName'] ?? data['email'] ?? 'No Name';
              final email = data['email'] ?? '-';
              final isAdmin = data['isAdmin'] as bool;
              final docRef = data['docRef'] as DocumentReference;

              return ListTile(
                tileColor: Colors.white,
                title: Text(displayName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('$email • ${isAdmin ? "Admin" : "User"}', style: GoogleFonts.poppins()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Delete ${isAdmin ? "admin" : "user"}?', style: GoogleFonts.poppins()),
                        content: Text('Are you sure you want to delete $displayName?', style: GoogleFonts.poppins()),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text('Delete', style: GoogleFonts.poppins(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await docRef.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${isAdmin ? "Admin" : "User"} deleted')),
                      );
                    }
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
