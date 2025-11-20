import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_detail.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({super.key});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  final requestsRef = FirebaseFirestore.instance.collection('booking_requests');
  final historyRef = FirebaseFirestore.instance.collection('approval_history');

  Future<void> _processRequest({
    required DocumentSnapshot requestDoc,
    required String newStatus,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final processedBy = user?.email ?? 'admin';
    final processedByUid = user?.uid ?? 'local-admin';

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final ref = requestsRef.doc(requestDoc.id);
      tx.update(ref, {
        'status': newStatus,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
        'processedByUid': processedByUid,
        if (reason != null) 'rejectionReason': reason,
      });

      final data = requestDoc.data() as Map<String, dynamic>;
      final history = {
        'requestId': requestDoc.id,
        'userId': data['userId'] ?? '',
        'userEmail': data['userEmail'] ?? '',
        'flightId': data['flightId'] ?? '',
        'flightNumber': data['flightNumber'] ?? '',
        'from': data['from'] ?? '',
        'to': data['to'] ?? '',
        'departureDate': data['departureDate'],
        'returnDate': data['returnDate'],
        'tripType': data['tripType'] ?? '',
        'seats': data['seats'] ?? 1,
        'action': newStatus,
        'reason': reason ?? '',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
        'processedByUid': processedByUid,
      };
      tx.set(historyRef.doc(), history);
    });
  }

  Widget _statusChip(String status) {
    Color c;
    switch (status) {
      case 'pending':
        c = Colors.orange;
        break;
      case 'accepted':
      case 'confirmed':
        c = Colors.green;
        break;
      case 'rejected':
      case 'cancelled':
        c = Colors.redAccent;
        break;
      case 'cancel_requested':
        c = Colors.purple;
        break;
      default:
        c = Colors.grey;
    }
    return Chip(
      label: Text(status),
      backgroundColor: c.withOpacity(0.15),
      labelStyle: GoogleFonts.poppins(color: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Requests', style: GoogleFonts.poppins()), // Removed (Table)
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: requestsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No booking requests'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
              child: DataTable(
                columns: [
                  DataColumn(label: Text('User', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Flight', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Route', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Dates', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Trip', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Seats', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Status', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                  DataColumn(label: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
                ],
                rows: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Text(data['userEmail'] ?? 'Unknown', style: GoogleFonts.poppins())),
                    DataCell(Text(data['flightId'] ?? '-', style: GoogleFonts.poppins())),
                    DataCell(Text('${data['from']} - ${data['to']}', style: GoogleFonts.poppins())),
                    DataCell(Text(
                      '${data['departureDate']?.toDate().toString().split(' ')[0]} - '
                      '${data['returnDate']?.toDate().toString().split(' ')[0]}',
                      style: GoogleFonts.poppins(),
                    )),
                    DataCell(Text(data['tripType'] ?? '-', style: GoogleFonts.poppins())),
                    DataCell(Text('${data['seats'] ?? 1}', style: GoogleFonts.poppins())),
                    DataCell(_statusChip(data['status'])),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await FirebaseFirestore.instance.runTransaction((tx) async {
                              final ref = d.reference;
                              tx.update(ref, {'status': 'accepted', 'processedAt': FieldValue.serverTimestamp()});

                              final booking = Map<String, dynamic>.from(data);
                              booking['status'] = 'confirmed';
                              booking['acceptedAt'] = FieldValue.serverTimestamp();
                              tx.set(FirebaseFirestore.instance.collection('bookings').doc(), booking);
                            });

                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(content: Text('Accepted')));
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.redAccent),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => BookingDetailPage(requestId: d.id)),
                            );
                          },
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
