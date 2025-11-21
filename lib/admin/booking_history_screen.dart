import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRef = FirebaseFirestore.instance.collection('approval_history');

    return Scaffold(
      appBar: AppBar(
        title: Text('Approval History', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF4B7B9A),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.orderBy('processedAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No approval history'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['userEmail']} - ${data['action']}', style: GoogleFonts.poppins()),
                subtitle: Text('Processed by: ${data['processedBy']} on ${data['processedAt']?.toDate().toString().split(' ')[0]}', style: GoogleFonts.poppins()),
              );
            },
          );
        },
      ),
    );
  }
}