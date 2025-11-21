import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class FlightManagementScreen extends StatefulWidget {
  const FlightManagementScreen({super.key});

  @override
  State<FlightManagementScreen> createState() => _FlightManagementScreenState();
}

class _FlightManagementScreenState extends State<FlightManagementScreen> {
  final bookingsRef = FirebaseFirestore.instance.collection('bookings');

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B7B9A);

    return Scaffold(
      appBar: AppBar(
        title: Text('Approved Flights', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            bookingsRef.where('status', isEqualTo: 'Confirmed').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('No approved flights'));

          // Get unique flights
          final flights = <String, Map<String, dynamic>>{};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final flightId = data['flightId'] ?? doc.id;
            if (!flights.containsKey(flightId)) {
              flights[flightId] = data;
            }
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: flights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final flightData = flights.values.elementAt(i);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${flightData['flightNumber'] ?? '-'} • ${flightData['departure'] ?? '-'} → ${flightData['destination'] ?? '-'}',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${flightData['travelDate'] ?? '-'} • Passengers: ${flightData['numPassengers'] ?? 1}',
                        style: GoogleFonts.poppins(fontSize: 14),
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
