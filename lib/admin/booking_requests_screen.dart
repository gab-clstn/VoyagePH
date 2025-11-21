import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final bookingsRef = FirebaseFirestore.instance.collection('bookings');
  final historyRef = FirebaseFirestore.instance.collection('approval_history');

  Future<void> _processBooking({
    required DocumentSnapshot bookingDoc,
    required String newStatus,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminEmail = user?.email ?? 'admin';
    final adminUid = user?.uid ?? 'local-admin';

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = bookingsRef.doc(bookingDoc.id);
      tx.update(ref, {
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminEmail,
        'processedByUid': adminUid,
        if (reason != null) 'rejectionReason': reason,
      });

      final data = bookingDoc.data() as Map<String, dynamic>;
      final history = {
        'bookingId': bookingDoc.id,
        'userId': data['userId'] ?? '',
        'userEmail': data['userEmail'] ?? '',
        'flightId': data['flightId'] ?? '',
        'flightNumber': data['flightNumber'] ?? '',
        'from': data['departure'] ?? '',
        'to': data['destination'] ?? '',
        'travelDate': data['travelDate'] ?? '',
        'numPassengers': data['numPassengers'] ?? 1,
        'seatNumber': data['seatNumber'] ?? '',
        'action': newStatus,
        'reason': reason ?? '',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': adminEmail,
        'processedByUid': adminUid,
      };
      tx.set(historyRef.doc(), history);
    });
  }

  Widget _statusChip(String status) {
    Color c;
    switch (status.toLowerCase()) {
      case 'pending':
        c = Colors.orange;
        break;
      case 'confirmed':
        c = Colors.green;
        break;
      case 'rejected':
        c = Colors.redAccent;
        break;
      default:
        c = Colors.grey;
    }
    return Chip(
      label: Text(status, style: GoogleFonts.poppins(color: c)),
      backgroundColor: c.withOpacity(0.15),
    );
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Requests', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookingsRef.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No booking requests'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = (data['status'] ?? 'Pending').toString();

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('User: ${data['userEmail'] ?? '-'}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Flight: ${data['flightNumber'] ?? '-'}',
                          style: GoogleFonts.poppins()),
                      Text(
                          'Route: ${data['departure'] ?? '-'} → ${data['destination'] ?? '-'}',
                          style: GoogleFonts.poppins()),
                      Text(
                          'Date: ${data['travelDate']?.toString().split('T')[0] ?? '-'}',
                          style: GoogleFonts.poppins()),
                      Text('Passengers: ${data['numPassengers'] ?? 1}',
                          style: GoogleFonts.poppins()),
                      Text('Seat: ${data['seatNumber'] ?? '-'}',
                          style: GoogleFonts.poppins()),
                      const SizedBox(height: 6),
                      _statusChip(status),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: status.toLowerCase() == 'pending'
                                ? () => _processBooking(
                                    bookingDoc: docs[index],
                                    newStatus: 'Confirmed')
                                : null,
                            child: const Text('Approve'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                            onPressed: status.toLowerCase() == 'pending'
                                ? () async {
                                    final reason = await _showRejectionDialog();
                                    if (reason != null && reason.isNotEmpty) {
                                      await _processBooking(
                                          bookingDoc: docs[index],
                                          newStatus: 'Rejected',
                                          reason: reason);
                                    }
                                  }
                                : null,
                            child: const Text('Reject'),
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
