import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Get the seat number from bookingData
  String getSeatNumber(Map<String, dynamic> data) {
    return data['seatNumber']?.toString() ?? 'N/A';
  }

  /// Get passenger names
  String getPassengerNames(Map<String, dynamic> data) {
    final passengers = data['passengers'] as List<dynamic>?;
    if (passengers != null && passengers.isNotEmpty) {
      final names = passengers.map((p) => p['name'] ?? 'Unknown').toList();
      return names.join(', ');
    } else if (data['passengerNames'] != null) {
      return data['passengerNames'].toString();
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final flightNumber = bookingData['flightNumber'] ?? '';
    final airline = bookingData['airline'] ?? '';
    final departure = bookingData['departure'] ?? '';
    final destination = bookingData['destination'] ?? '';
<<<<<<< HEAD
    final travelDate = bookingData['travelDate'] != null
        ? bookingData['travelDate'].toString().split(
            'T',
          )[0] // if ISO string format
        : '';
=======
    final travelDate =
        bookingData['travelDate']?.toString().split('T')[0] ?? '';
>>>>>>> 1605e8416e41a7821947ac9caaac910f67808007
    final seatClass = bookingData['seatClass'] ?? '';
    final totalFare = bookingData['totalFare'] ?? 0;
    final notes = bookingData['notes'] ?? '';
    final paymentMethod = bookingData['paymentMethod'] ?? '';
    final bookingType = bookingData['bookingType'] ?? 'Single Flight';

<<<<<<< HEAD
    final passengers =
        (bookingData['passengers'] as List<dynamic>?)
            ?.map(
              (p) => {
                'name': p['name'] ?? '',
                'ageGroup': p['ageGroup'] ?? '',
                'seatNumber': p['seatNumber'] ?? 'N/A',
                'infantSeating': p['infantSeating'] ?? '',
              },
            )
            .toList() ??
        [];
=======
    final passengers = getPassengerNames(bookingData);
    final seatNumber = getSeatNumber(bookingData);
>>>>>>> 1605e8416e41a7821947ac9caaac910f67808007

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
            Container(
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
<<<<<<< HEAD
                  const Divider(thickness: 1),
=======
                  // Perforated Line
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        height: 1,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          50,
                          (index) => Container(
                            width: 4,
                            height: 1,
                            color: index % 2 == 0
                                ? Colors.white
                                : Colors.grey[200],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bottom Section: Details
>>>>>>> 1605e8416e41a7821947ac9caaac910f67808007
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
<<<<<<< HEAD
                        Text(
                          'Booking Type: $bookingType',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Passengers',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...passengers.map(
                          (p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${p['name']}'),
                                Text('Age Group: ${p['ageGroup']}'),
                                if (p['ageGroup'] == 'Infant (0-2)')
                                  Text('Infant Seating: ${p['infantSeating']}'),
                                Text('Seat: ${p['seatNumber']}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
=======
                        _ticketRow('Passenger(s)', passengers),
                        _ticketRow('Seat', seatNumber),
>>>>>>> 1605e8416e41a7821947ac9caaac910f67808007
                        _ticketRow('Date', travelDate),
                        _ticketRow('Class', seatClass),
                        _ticketRow('Total Fare', '₱$totalFare'),
                        _ticketRow('Payment Method', paymentMethod),
                        if (notes.isNotEmpty) _ticketRow('Notes', notes),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
