// lib/screens/flight_ticket_page.dart
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

    // SAFE NUM PASSENGERS (fallback)
    final storedNumPassengers =
        (bookingData['numPassengers'] as num?)?.toInt() ?? passengers.length;
    final int numPassengers = storedNumPassengers > 0
        ? storedNumPassengers
        : passengers.length;

    // ROUND TRIP CHECK
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
      // optional price if present on booking
      'price':
          (bookingData['fareOutbound'] as num?)?.toDouble() ??
          (bookingData['outboundPrice'] as num?)?.toDouble() ??
          (bookingData['flight'] is Map
              ? (bookingData['flight']['price'] as num?)?.toDouble()
              : null) ??
          null,
    };

    // RETURN SAFE MAP
    final returnFlight = isRoundTrip
        ? {
            'airline': returnFlightData['airline'] ?? '',
            'flightNumber': returnFlightData['flightNumber'] ?? '',
            'departure': returnFlightData['departure'] ?? '',
            'destination': returnFlightData['destination'] ?? '',
            'travelDate': bookingData['returnDate'] ?? '',
            'departureTime': returnFlightData['departureTime'] ?? '',
            'arrivalTime': returnFlightData['arrivalTime'] ?? '',
            'seatClass': bookingData['seatClass'] ?? '',
            'price':
                (bookingData['fareReturn'] as num?)?.toDouble() ??
                (bookingData['returnPrice'] as num?)?.toDouble() ??
                (returnFlightData is Map
                    ? (returnFlightData['price'] as num?)?.toDouble()
                    : null) ??
                null,
          }
        : null;

    // -------------------- FARE LOGIC (robust) --------------------
    //
    // We try several sources (explicit fareOutbound/fareReturn,
    // flight/returnFlight maps, or finally the top-level 'fare'
    // which historically has been the total booking price).
    //
    // If only the total booking fare is stored, we compute a per-passenger
    // value and split evenly across legs for round trips.
    //

    final double? explicitOutbound =
        (bookingData['fareOutbound'] as num?)?.toDouble() ??
        (bookingData['outboundPrice'] as num?)?.toDouble() ??
        (outboundFlight['price'] as double?);

    final double? explicitReturn =
        (bookingData['fareReturn'] as num?)?.toDouble() ??
        (bookingData['returnPrice'] as num?)?.toDouble() ??
        (returnFlight != null ? returnFlight['price'] as double? : null);

    final double totalFareStored = (bookingData['fare'] as num? ?? 0)
        .toDouble(); // often equals whole booking total

    double fareOutbound = explicitOutbound ?? 0.0;
    double fareReturn = explicitReturn ?? 0.0;

    // If both legs present explicitly, do nothing extra.
    if (fareOutbound > 0 && (!isRoundTrip || fareReturn > 0)) {
      // good — explicit values already set
    } else {
      // we must infer from totalFareStored (if present)
      if (totalFareStored > 0 && numPassengers > 0) {
        // totalFareStored is likely the entire booking price (all passengers).
        // compute per-passenger booking total:
        final perPassengerTotal = totalFareStored / numPassengers;

        if (isRoundTrip) {
          // If both explicit are zero -> split per passenger total evenly across legs
          if (fareOutbound == 0 && fareReturn == 0) {
            fareOutbound = perPassengerTotal / 2;
            fareReturn = perPassengerTotal / 2;
          } else if (fareOutbound > 0 && fareReturn == 0) {
            // use explicit outbound, compute return as remainder of perPassengerTotal
            fareReturn = (perPassengerTotal - fareOutbound).clamp(
              0.0,
              perPassengerTotal,
            );
            // if computed zero (e.g., perPassengerTotal == fareOutbound), keep return 0
          } else if (fareReturn > 0 && fareOutbound == 0) {
            fareOutbound = (perPassengerTotal - fareReturn).clamp(
              0.0,
              perPassengerTotal,
            );
          }
        } else {
          // One-way: if outbound missing, use perPassengerTotal
          if (fareOutbound == 0) {
            fareOutbound = perPassengerTotal;
          }
          // ensure fareReturn is zero for one-way
          fareReturn = 0.0;
        }
      } else {
        // No total stored -> as last resort use any price embedded in returned maps or 0
        fareOutbound = fareOutbound > 0 ? fareOutbound : 0.0;
        fareReturn = isRoundTrip ? (fareReturn > 0 ? fareReturn : 0.0) : 0.0;
      }
    }

    // Final safety: ensure values are non-negative
    fareOutbound = (fareOutbound < 0) ? 0.0 : fareOutbound;
    fareReturn = (fareReturn < 0) ? 0.0 : fareReturn;

    // Compute total fare for display (sum per passenger * number passengers)
    final totalFare =
        (fareOutbound + (isRoundTrip ? fareReturn : 0)) * passengers.length;

    final formattedTotalFare = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
    ).format(totalFare);

    // ---------------------------------------------------------

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
              child: ListView(
                children: [
                  // OUTBOUND TICKET
                  ..._generateTickets(
                    passengers: passengers,
                    flight: outboundFlight,
                    title: 'Outbound Flight',
                    farePerLeg: fareOutbound,
                  ),

                  // RETURN TICKET
                  if (isRoundTrip && returnFlight != null)
                    ..._generateTickets(
                      passengers: passengers,
                      flight: returnFlight,
                      title: 'Return Flight',
                      farePerLeg: fareReturn,
                    ),

                  // TOTAL FARE DISPLAY
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Fare',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            formattedTotalFare,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
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
              icon: const Icon(Icons.cancel_outlined, color: Colors.white),
              label: const Text(
                'Cancel Booking',
                style: TextStyle(fontSize: 18, color: Colors.white),
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
    required double farePerLeg,
  }) {
    final formattedFarePerLeg = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
    ).format(farePerLeg);

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      ...passengers.map(
        (p) => _singleTicket(
          passenger: p,
          flight: flight,
          farePerLeg: formattedFarePerLeg,
        ),
      ),
      const SizedBox(height: 20),
    ];
  }

  Widget _singleTicket({
    required Map<String, dynamic> passenger,
    required Map<String, dynamic> flight,
    required String farePerLeg,
  }) {
    final travelDate = (flight['travelDate'] ?? '').toString();
    final formattedDate = travelDate.contains('T')
        ? travelDate.split('T')[0]
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
              children: [
                // LEFT COLUMN
                Expanded(
                  child: Column(
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
                ),

                // CENTER ICON (always perfectly centered)
                Icon(Icons.airplanemode_active, color: Colors.white, size: 32),

                // RIGHT COLUMN
                Expanded(
                  child: Column(
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
                _ticketRow("Passenger", passenger['name'] ?? ''),
                _ticketRow("Age Group", passenger['ageGroup'] ?? ''),
                if ((passenger['ageGroup'] ?? '') == "Infant (0-2)")
                  _ticketRow(
                    "Infant Seating",
                    passenger['infantSeating'] ?? '',
                  ),
                _ticketRow("Seat", passenger['seatNumber'] ?? ''),
                _ticketRow("Date", formattedDate),
                _ticketRow("Departure Time", flight['departureTime'] ?? ''),
                _ticketRow("Arrival Time", flight['arrivalTime'] ?? ''),
                _ticketRow("Class", flight['seatClass'] ?? ''),
                _ticketRow("Fare", farePerLeg),
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
