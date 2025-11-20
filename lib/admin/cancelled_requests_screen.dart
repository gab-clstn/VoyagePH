import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CancelledRequestsScreen extends StatelessWidget {
  const CancelledRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cancelledRef = FirebaseFirestore.instance
        .collection('booking_requests')
        .where('status', isEqualTo: 'cancel_requested');

    final primary = const Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cancel Requests', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cancelledRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No cancellation requests found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    data['userEmail'] ?? 'Unknown user',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${data['from']} → ${data['to']}\nFlight: ${data['flightNumber'] ?? '-'}",
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('booking_requests')
                          .doc(d.id)
                          .update({
                        'status': 'cancelled',
                        'processedAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cancellation Approved')),
                      );
                    },
                    child: const Text("Approve"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
