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
    // PASSENGERS SAFE PARSED
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

    // 🌟 FIXED: SAFE ROUND TRIP CHECK
    final returnFlightData =
        (bookingData['returnFlight'] as Map<dynamic, dynamic>?);

    final bool isRoundTrip =
        returnFlightData != null && returnFlightData.isNotEmpty;

    // OUTBOUND SAFE MAP
    final outboundFlight = {
      'airline': bookingData['airline'] ?? '',
      'flightNumber': bookingData['flightNumber'] ?? '',
      'departure': bookingData['departure'] ?? '',
      'destination': bookingData['destination'] ?? '',
      'travelDate': bookingData['travelDate'] ?? '',
      'departureTime': bookingData['departureTime'] ?? '',
      'arrivalTime': bookingData['arrivalTime'] ?? '',
      'seatClass': bookingData['seatClass'] ?? '',
    };

    // RETURN SAFE MAP
    final returnFlight = isRoundTrip
        ? {
            'airline': returnFlightData['airline'] ?? '',
            'flightNumber': returnFlightData['flightNumber'] ?? '',
            'departure': returnFlightData['departure'] ?? '',
            'destination': returnFlightData['destination'] ?? '',
            'travelDate': returnFlightData['travelDate'] ?? '',
            'departureTime': returnFlightData['departureTime'] ?? '',
            'arrivalTime': returnFlightData['arrivalTime'] ?? '',
            'seatClass': bookingData['seatClass'] ?? '',
          }
        : null;

    // FARE SAFE
    final totalFare =
        (bookingData['fareTotal'] ??
                bookingData['totalFare'] ??
                bookingData['finalTotal'] ??
                0)
            .toDouble();

    final formattedFare = NumberFormat('#,##0.00').format(totalFare);

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

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  // OUTBOUND TICKET
                  ..._generateTickets(
                    passengers: passengers,
                    flight: outboundFlight,
                    title: "Outbound Flight",
                    totalFare: formattedFare,
                  ),

                  // RETURN TICKET
                  if (isRoundTrip && returnFlight != null)
                    ..._generateTickets(
                      passengers: passengers,
                      flight: returnFlight,
                      title: "Return Flight",
                      totalFare: formattedFare,
                    ),
                ],
              ),
            ),

            // CANCEL BUTTON
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

  // ------------------- TICKET BUILDER -------------------

  List<Widget> _generateTickets({
    required List<Map<String, dynamic>> passengers,
    required Map<String, dynamic> flight,
    required String title,
    required String totalFare,
  }) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      ...passengers.map(
        (p) =>
            _singleTicket(passenger: p, flight: flight, totalFare: totalFare),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _singleTicket({
    required Map<String, dynamic> passenger,
    required Map<String, dynamic> flight,
    required String totalFare,
  }) {
    final travelDate = (flight['travelDate'] ?? '').toString();
    final formattedDate = travelDate.contains("T")
        ? travelDate.split("T")[0]
        : travelDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // HEADER
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
                // Airline
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['airline'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flight['flightNumber'],
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
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
                      flight['departure'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      flight['destination'],
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(thickness: 1),

          // BODY CONTENT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ticketRow("Passenger", passenger['name']),
                _ticketRow("Age Group", passenger['ageGroup']),
                if (passenger['ageGroup'] == "Infant (0-2)")
                  _ticketRow("Infant Seating", passenger['infantSeating']),
                _ticketRow("Seat", passenger['seatNumber']),
                _ticketRow("Date", formattedDate),
                _ticketRow("Departure Time", flight['departureTime']),
                _ticketRow("Arrival Time", flight['arrivalTime']),
                _ticketRow("Class", flight['seatClass']),
                _ticketRow("Fare", "₱$totalFare"),
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
