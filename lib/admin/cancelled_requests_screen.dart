import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CancelledRequestsScreen extends StatelessWidget {
  const CancelledRequestsScreen({super.key});

  Future<void> _processCancelRequest(
      BuildContext context, DocumentSnapshot doc, bool approve) async {
    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'admin';

    try {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['userId'] ?? '';

      // Update cancel request status
      await FirebaseFirestore.instance
          .collection('cancel_requests')
          .doc(doc.id)
          .update({
        'status': approve ? 'Approved' : 'Rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminEmail,
      });

      // If approved, update the booking status to 'Cancelled'
      if (approve) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(data['bookingId'])
            .update({
          'status': 'Cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        // Send notification to user in Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Booking Cancelled',
          'message':
              'Your booking for flight ${data['flightNumber']} on ${data['travelDate']?.toString().split('T')[0]} has been cancelled.',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Email will be sent automatically by Cloud Function triggered by this Firestore change
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(approve
                ? 'Cancellation Approved and user notified'
                : 'Cancellation Rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cancelRef = FirebaseFirestore.instance
        .collection('cancel_requests')
        .where('status', isEqualTo: 'Pending'); // pending requests only

    const primary = Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cancel Requests', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cancelRef.snapshots(),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.redAccent.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userEmail'] ?? 'Unknown user',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Flight: ${data['flightNumber'] ?? '-'}\n"
                        "Route: ${data['departure'] ?? '-'} → ${data['destination'] ?? '-'}\n"
                        "Date: ${data['travelDate']?.toString().split('T')[0] ?? '-'}",
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _processCancelRequest(context, d, true),
                            child: const Text("Approve"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () =>
                                _processCancelRequest(context, d, false),
                            child: const Text("Reject"),
                          ),
                        ],
                      ),
                    ],
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
