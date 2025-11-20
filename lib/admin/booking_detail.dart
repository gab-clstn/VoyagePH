import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingDetailPage extends StatefulWidget {
  final String requestId;
  const BookingDetailPage({super.key, required this.requestId});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool _processing = false;
  String? _reason;

  Future<DocumentSnapshot> _doc() => FirebaseFirestore.instance.collection('booking_requests').doc(widget.requestId).get();

  Future<void> _reject(String reason, DocumentSnapshot snap) async {
    setState(() => _processing = true);
    try {
      await snap.reference.update({'status': 'rejected', 'rejectionReason': reason, 'processedAt': FieldValue.serverTimestamp()});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
      if (context.mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _accept(DocumentSnapshot snap) async {
    setState(() => _processing = true);
    try {
      final data = snap.data() as Map<String, dynamic>;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(snap.reference, {'status': 'accepted', 'processedAt': FieldValue.serverTimestamp()});
        final booking = Map<String, dynamic>.from(data);
        booking['status'] = 'confirmed';
        booking['acceptedAt'] = FieldValue.serverTimestamp();
        tx.set(FirebaseFirestore.instance.collection('bookings').doc(), booking);
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted')));
      if (context.mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(title: Text('Booking Detail', style: GoogleFonts.poppins()), backgroundColor: primary),
      body: FutureBuilder<DocumentSnapshot>(
        future: _doc(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) return const Center(child: Text('Not found'));
          final data = snap.data!.data() as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('User: ${data['userEmail'] ?? '-'}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Flight: ${data['flightId'] ?? '-'}', style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text('Seats: ${data['seats'] ?? 1}', style: GoogleFonts.poppins()),
              const SizedBox(height: 12),
              Text('Notes:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(data['notes'] ?? '-', style: GoogleFonts.poppins()),
              const Spacer(),
              if (_processing) const Center(child: CircularProgressIndicator()) else Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _accept(snap.data!),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    child: Text('Accept', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final reason = await showDialog<String>(
                        context: context,
                        builder: (ctx) {
                          final ctrl = TextEditingController();
                          return AlertDialog(
                            title: Text('Rejection reason', style: GoogleFonts.poppins()),
                            content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason')),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(ctx).pop(null), child: Text('Cancel', style: GoogleFonts.poppins())),
                              TextButton(onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()), child: Text('Reject', style: GoogleFonts.poppins())),
                            ],
                          );
                        },
                      );
                      if (reason != null && reason.isNotEmpty) {
                        await _reject(reason, snap.data!);
                      }
                    },
                    child: Text('Reject', style: GoogleFonts.poppins()),
                  ),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}