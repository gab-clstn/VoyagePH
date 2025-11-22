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
    final usersRef = FirebaseFirestore.instance.collection('users');
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('admins')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, adminSnap) {
              if (!adminSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- USERS ---
              final users = userSnap.data!.docs
                  .map((d) => {
                        ...d.data() as Map<String, dynamic>,
                        'isAdmin': false,
                        'docRef': d.reference,
                      })
                  .toList();

              // --- ADMINS ---
              final admins = adminSnap.data!.docs
                  .map((d) => {
                        ...d.data() as Map<String, dynamic>,
                        'isAdmin': true,
                        'docRef': d.reference,
                      })
                  .toList();

              // MERGE THEM
              final all = [...users, ...admins];

              if (all.isEmpty) {
                return const Center(child: Text("No users found"));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: all.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = all[i];
                  final name = data['displayName'] ?? data['email'] ?? 'No Name';
                  final email = data['email'] ?? '-';
                  final isAdmin = data['isAdmin'];
                  final docRef = data['docRef'] as DocumentReference;

                  return ListTile(
                    tileColor: Colors.white,
                    title: Text(name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '$email • ${isAdmin ? "Admin" : "User"}',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(
                                'Delete ${isAdmin ? "admin" : "user"}?',
                                style: GoogleFonts.poppins()),
                            content: Text(
                                'Are you sure you want to delete $name?',
                                style: GoogleFonts.poppins()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text("Cancel",
                                    style: GoogleFonts.poppins()),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text("Delete",
                                    style: GoogleFonts.poppins(
                                        color: Colors.red)),
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
          );
        },
      ),
    );
  }
}