import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FlightTicketPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const FlightTicketPage({
    required this.bookingData,
    required this.bookingId,
    super.key,
  });

  Future<void> _requestCancelBooking(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

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
          .where('bookingId', isEqualTo: bookingId)
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
        'bookingId': bookingId,
        'userId': user?.uid,
        'userEmail': user?.email ?? '',
        'flightId': bookingData['flightId'] ?? '',
        'flightNumber': bookingData['flightNumber'] ?? '',
        'departure': bookingData['departure'] ?? '',
        'destination': bookingData['destination'] ?? '',
        'travelDate': bookingData['travelDate'] ?? '',
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

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
    final flightNumber = bookingData['flightNumber'] ?? '';
    final airline = bookingData['airline'] ?? '';
    final departure = bookingData['departure'] ?? '';
    final destination = bookingData['destination'] ?? '';
    final travelDate = bookingData['travelDate'] != null
        ? bookingData['travelDate'].toString().split('T')[0]
        : '';
    final seatClass = bookingData['seatClass'] ?? '';

    final totalFare =
        bookingData['fareTotal'] ??
        bookingData['totalFare'] ??
        bookingData['fare'] ??
        bookingData['finalTotal'] ??
        bookingData['amount'] ??
        bookingData['price'] ??
        0;

    // 🔥 FORMAT FARE HERE
    final formattedFare = NumberFormat('#,##0.00').format(totalFare);

    final notes = bookingData['notes'] ?? '';
    final paymentMethod = bookingData['paymentMethod'] ?? '';
    final bookingType = bookingData['bookingType'] ?? 'Single Flight';
    final departureTime = bookingData['departureTime'] ?? '';
    final arrivalTime = bookingData['arrivalTime'] ?? '';
    final passengers = (bookingData['passengers'] as List<dynamic>? ?? [])
        .map(
          (p) => {
            'name': p['name'] ?? '',
            'ageGroup': p['ageGroup'] ?? '',
            'seatNumber': p['seatNumber'] ?? 'N/A',
            'infantSeating': p['infantSeating'] ?? '',
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        title: Text(
          'Flight Ticket',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: passengers.length,
                itemBuilder: (context, index) {
                  final passenger = passengers[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _singleTicket(
                      passenger: passenger,
                      flightNumber: flightNumber,
                      airline: airline,
                      departure: departure,
                      destination: destination,
                      travelDate: travelDate,
                      seatClass: seatClass,
                      totalFare: formattedFare,
                      paymentMethod: paymentMethod,
                      notes: notes,
                      bookingType: bookingType,
                      departureTime: departureTime,
                      arrivalTime: arrivalTime,
                    ),
                  );
                },
              ),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => _requestCancelBooking(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _singleTicket({
    required Map<String, dynamic> passenger,
    required String flightNumber,
    required String airline,
    required String departure,
    required String destination,
    required String travelDate,
    required String seatClass,
    required String totalFare,
    required String paymentMethod,
    required String notes,
    required String bookingType,
    required String departureTime,
    required String arrivalTime,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airline,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flightNumber,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.airplanemode_active,
                  color: Colors.white,
                  size: 32,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      departure,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination,
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(thickness: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Type: $bookingType',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Passenger Information',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ticketRow('Name', passenger['name']),
                _ticketRow('Age Group', passenger['ageGroup']),
                if (passenger['ageGroup'] == 'Infant (0-2)')
                  _ticketRow('Infant Seating', passenger['infantSeating']),
                _ticketRow('Seat', passenger['seatNumber']),
                _ticketRow('Date', travelDate),
                _ticketRow('Departure Time', departureTime),
                _ticketRow('Arrival Time', arrivalTime),
                _ticketRow('Class', seatClass),

                // 🔥 Formatted fare here
                _ticketRow('Fare', '₱$totalFare'),

                _ticketRow('Payment', paymentMethod),
                if (notes.isNotEmpty) _ticketRow('Notes', notes),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
