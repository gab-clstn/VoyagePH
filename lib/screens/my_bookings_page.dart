import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flight_ticket_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  String? _justCancelledBookingId;

  Future<void> _requestCancelBooking(
    BuildContext context,
    DocumentSnapshot doc,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final data = doc.data() as Map<String, dynamic>;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final existing = await FirebaseFirestore.instance
          .collection('cancel_requests')
          .where('bookingId', isEqualTo: doc.id)
          .where('status', isEqualTo: 'Pending')
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already requested to cancel this booking'),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('cancel_requests').add({
        'bookingId': doc.id,
        'userId': user?.uid,
        'userEmail': user?.email ?? '',
        'flightId': data['flightId'] ?? '',
        'flightNumber': data['flightNumber'] ?? '',
        'departure': data['departure'] ?? '',
        'destination': data['destination'] ?? '',
        'travelDate': data['travelDate'] ?? '',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      setState(() => _justCancelledBookingId = doc.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cancellation request submitted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final bookings = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    final cancelRequests = FirebaseFirestore.instance
        .collection('cancel_requests')
        .where('userId', isEqualTo: user?.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        centerTitle: true,
        title: Text(
          'My Bookings',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: bookings,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                'You have no bookings yet.',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: cancelRequests,
            builder: (context, cancelSnap) {
              final cancelDocs = cancelSnap.data?.docs ?? [];

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;

                  // 🔥 FIXED: Correct total fare value
                  final totalFare =
                      data['fareTotal'] ??
                      data['totalFare'] ??
                      data['fare'] ??
                      data['finalTotal'] ??
                      0;

                  final flightName =
                      '${data['airline'] ?? ''} ${data['flightNumber'] ?? ''}';

                  final passengerList =
                      (data['passengers'] as List<dynamic>?) ?? [];

                  final passengers = passengerList.isNotEmpty
                      ? passengerList
                            .map(
                              (p) => (p as Map<String, dynamic>)['name'] ?? '',
                            )
                            .where((n) => n.isNotEmpty)
                            .join(', ')
                      : (data['passengerNames'] as String?) ?? '';

                  String seats;
                  if (passengerList.isNotEmpty) {
                    final perSeats = passengerList.map((p) {
                      final s = (p as Map<String, dynamic>)['seatNumber'];
                      return s != null && s.toString().isNotEmpty
                          ? s.toString()
                          : null;
                    }).toList();

                    final hasAnyPerSeat = perSeats.any((s) => s != null);

                    if (hasAnyPerSeat) {
                      final fallback = data['seatNumber']?.toString() ?? 'N/A';
                      seats = perSeats.map((s) => s ?? fallback).join(', ');
                    } else {
                      seats = data['seatNumber']?.toString() ?? 'N/A';
                    }
                  } else {
                    seats = data['seatNumber']?.toString() ?? 'N/A';
                  }

                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();

                  final cancelRequested = cancelDocs.any(
                    (c) =>
                        (c.data() as Map<String, dynamic>)['bookingId'] ==
                            docs[index].id &&
                        (c.data() as Map<String, dynamic>)['status'] ==
                            'Pending',
                  );

                  final highlightRed =
                      _justCancelledBookingId == docs[index].id;

                  final baseStyle = GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  );

                  final labelStyle = baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  );

                  final statusColor = status == 'confirmed'
                      ? Colors.green
                      : (status == 'rejected' || status == 'cancelled')
                      ? Colors.red
                      : (status == 'pending' ? Colors.orange : Colors.black87);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: highlightRed
                          ? const BorderSide(color: Colors.redAccent, width: 2)
                          : BorderSide.none,
                    ),
                    color: status == 'confirmed'
                        ? Colors.green.withOpacity(0.08)
                        : (status == 'rejected' || status == 'cancelled')
                        ? Colors.red.withOpacity(0.08)
                        : status == 'pending'
                        ? Colors.orange.withOpacity(0.08)
                        : Colors.white,
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shadowColor: Colors.black26,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FlightTicketPage(
                              bookingData: data,
                              bookingId: docs[index].id,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: const Icon(
                          Icons.airplane_ticket,
                          color: Colors.blue,
                          size: 32,
                        ),
                        title: Text(
                          flightName,
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        subtitle: Text.rich(
                          TextSpan(
                            style: baseStyle,
                            children: [
                              TextSpan(text: 'Passenger: ', style: labelStyle),
                              TextSpan(
                                text: passengers.isNotEmpty
                                    ? passengers
                                    : 'N/A',
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'Seat: ', style: labelStyle),
                              TextSpan(text: seats),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'Class: ', style: labelStyle),
                              TextSpan(text: data['seatClass'] ?? 'N/A'),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'Date: ', style: labelStyle),
                              TextSpan(
                                text:
                                    data['travelDate']?.toString().split(
                                      'T',
                                    )[0] ??
                                    'N/A',
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'Status: ', style: labelStyle),
                              TextSpan(
                                text: (data['status'] ?? 'N/A').toString(),
                                style: baseStyle.copyWith(color: statusColor),
                              ),
                              const TextSpan(text: '\n'),
                              TextSpan(text: 'Total: ', style: labelStyle),

                              /// 🔥 FIXED LINE: now uses the actual fare
                              TextSpan(text: '₱${totalFare.toString()}'),
                            ],
                          ),
                        ),
                        trailing: (status == 'pending' || status == 'confirmed')
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  color: Colors.redAccent,
                                ),
                                onPressed: cancelRequested
                                    ? null
                                    : () => _requestCancelBooking(
                                        context,
                                        docs[index],
                                      ),
                              )
                            : null,
                      ),
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
