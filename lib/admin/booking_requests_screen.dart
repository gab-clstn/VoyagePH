import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_detail.dart';

class BookingRequestsScreen extends StatelessWidget {
  const BookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    final requestsRef = FirebaseFirestore.instance.collection('booking_requests');
    return Scaffold(
      appBar: AppBar(title: Text('Booking Requests', style: GoogleFonts.poppins()), backgroundColor: primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsRef.where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No pending requests'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                title: Text(data['userEmail'] ?? 'Unknown', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text('Flight: ${data['flightId'] ?? '-'} • Seats: ${data['seats'] ?? 1}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      // accept request
                      await FirebaseFirestore.instance.runTransaction((tx) async {
                        final ref = d.reference;
                        tx.update(ref, {'status': 'accepted', 'processedAt': FieldValue.serverTimestamp()});
                        // copy to bookings collection
                        final booking = Map<String, dynamic>.from(data);
                        booking['status'] = 'confirmed';
                        booking['acceptedAt'] = FieldValue.serverTimestamp();
                        tx.set(FirebaseFirestore.instance.collection('bookings').doc(), booking);
                      });
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accepted')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingDetailPage(requestId: d.id)));
                    },
                  ),
                ]),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingDetailPage(requestId: d.id))),
              );
            },
          );
        },
      ),
    );
  }
}