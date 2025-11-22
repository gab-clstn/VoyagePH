// admin_booking_history_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingHistoryTab extends StatelessWidget {
  const BookingHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final historyRef = FirebaseFirestore.instance.collection('approval_history');
    final primary = const Color(0xFF4B7B9A);

    // Status color coding
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'confirmed':
        case 'accepted':
          return Colors.green;
        case 'rejected':
          return Colors.red;
        case 'cancelled':
          return Colors.redAccent;
        case 'cancel_requested':
          return Colors.purple;
        default:
          return Colors.orange;
      }
    }

    // Readable status label
    String getReadableStatus(String status) {
      switch (status.toLowerCase()) {
        case 'accepted':
        case 'confirmed':
          return "Booking Confirmed";
        case 'rejected':
          return "Booking Rejected";
        case 'cancel_requested':
          return "Cancellation Requested";
        case 'cancelled':
          return "Booking Cancelled";
        default:
          return "Updated Status";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking History', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historyRef.orderBy('processedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No history records'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final processedAt = data['processedAt'] != null
                  ? (data['processedAt'] as Timestamp)
                      .toDate()
                      .toLocal()
                      .toString()
                      .split(' ')[0]
                  : '-';

              final status = (data['action'] ?? '-').toString();
              final readableLabel = getReadableStatus(status);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${data['userEmail'] ?? '-'} → ${data['flightNumber'] ?? '-'}',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: getStatusColor(status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: GoogleFonts.poppins(
                                  color: getStatusColor(status), fontSize: 12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Readable Label
                      Text(
                        readableLabel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(status),
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Details
                      Text('Route: ${data['from']} → ${data['to']}',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      Text('Processed By: ${data['processedBy'] ?? '-'}',
                          style: GoogleFonts.poppins(fontSize: 12)),
                      Text('Date: $processedAt',
                          style: GoogleFonts.poppins(fontSize: 12)),
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
