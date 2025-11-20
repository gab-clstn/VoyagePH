import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_page.dart';
import 'package:google_fonts/google_fonts.dart';

class FlightsPage extends StatefulWidget {
  final String? from;
  final String? to;
  final DateTime? departureDate;

  const FlightsPage({super.key, this.from, this.to, this.departureDate});

  @override
  State<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends State<FlightsPage> {
  List<Map<String, dynamic>> flights = [];
  final user = FirebaseAuth.instance.currentUser;
  final Random _random = Random();

  final List<String> locations = [
    'Bacolod',
    'Bohol',
    'Boracay (Caticlan)',
    'Butuan',
    'Cagayan De Oro',
    'Calbayog',
    'Camiguin',
    'Cauayan',
    'Cebu',
    'Clark',
    'Coron (Basuanga)',
    'Cotabato',
    'Davao',
    'Dipolog',
    'Dumaguete',
    'El Nido',
    'General Santos',
    'Iloilo',
    'Kalibo',
    'Laoag',
    'Legazpi (Daraga)',
    'Manila',
    'Masbate',
    'Naga',
    'Ozamiz',
    'Pagadian',
    'Puerto Princesa',
    'Roxas',
    'San Jose (Mindoro)',
    'San Vicente (Port Barton)',
    'Siargao',
    'Surigao',
    'Tacloban',
    'Tawi-Tawi',
    'Tuguegarao',
    'Virac',
    'Zamboanga',
  ];

  @override
  void initState() {
    super.initState();
    generateFlights();
  }

  String calculateArrival(String depTime, int durationHours) {
    // depTime e.g., "06:00 AM"
    final parts = depTime.split(' '); // ["06:00", "AM"]
    final timeParts = parts[0].split(':'); // ["06","00"]
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    final ampm = parts[1];

    // convert to 24h
    if (ampm == "PM" && hour != 12) hour += 12;
    if (ampm == "AM" && hour == 12) hour = 0;

    // add duration
    hour = (hour + durationHours) % 24;

    // convert back to 12h format
    String newAmpm = hour >= 12 ? "PM" : "AM";
    int displayHour = hour % 12;
    if (displayHour == 0) displayHour = 12;

    return "${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $newAmpm";
  }

  void generateFlights() {
    final airlines = [
      'Philippine Airlines',
      'Cebu Pacific',
      'AirAsia',
      'PAL Express',
    ];
    final times = [
      '06:00 AM',
      '06:30 AM',
      '07:00 AM',
      '08:00 AM',
      '09:45 AM',
      '10:00 AM',
      '01:00 PM',
      '03:00 PM',
      '06:00 PM',
    ];

    List<Map<String, dynamic>> tempFlights = List.generate(
      5 + _random.nextInt(5), // 5-9 flights
      (index) {
        String from;
        String to;

        if (widget.from != null && widget.to != null) {
          // If coming from search, use the specified from/to
          from = widget.from!;
          to = widget.to!;
        } else {
          // Random flight: pick two different random locations
          from = locations[_random.nextInt(locations.length)];
          to = locations[_random.nextInt(locations.length)];
          while (to == from) {
            to = locations[_random.nextInt(locations.length)];
          }
        }

        final depTime = times[_random.nextInt(times.length)];

        // Parse hour & minute safely
        final depHour = int.parse(depTime.split(':')[0]);
        final depMinute = int.parse(depTime.split(':')[1].split(' ')[0]);
        final depPeriod = depTime.split(' ')[1];

        // Convert to 24-hour format
        int depHour24 = depHour;
        if (depPeriod == 'PM' && depHour != 12) depHour24 += 12;
        if (depPeriod == 'AM' && depHour == 12) depHour24 = 0;

        final arrHour24 = (depHour24 + 2) % 24;
        final arrTime =
            '${arrHour24.toString().padLeft(2, '0')}:${depMinute.toString().padLeft(2, '0')}';

        final now = DateTime.now();
        final departureDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          depHour24,
          depMinute,
        );

        return {
          'airline': airlines[_random.nextInt(airlines.length)],
          'flightNumber': 'PH${100 + _random.nextInt(900)}',
          'departure': from,
          'destination': to,
          'departureTime':
              '${departureDateTime.hour.toString().padLeft(2, '0')}:${departureDateTime.minute.toString().padLeft(2, '0')}',
          'arrivalTime': arrTime,
          'status': _random.nextBool() ? 'Scheduled' : 'Delayed',
        };
      },
    );

    setState(() {
      flights = tempFlights;
    });
  }

  Future<void> bookFlight(Map<String, dynamic> flight) async {
    if (user == null) return;

    final bookings = FirebaseFirestore.instance.collection('bookings');
    await bookings.add({
      'userId': user!.uid,
      'airline': flight['airline'],
      'flightNumber': flight['flightNumber'],
      'arrival': flight['destination'],
      'departure': flight['departure'],
      'departureTime': flight['departureTime'],
      'status': 'Booked',
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Flight booked successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        centerTitle: true,
        elevation: 4,
        shadowColor: Colors.black26,
        title: Text(
          widget.from != null && widget.to != null
              ? '${widget.from} → ${widget.to} Flights'
              : 'FLIGHT SCHEDULES',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
      body: flights.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => generateFlights(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: flights.length,
                itemBuilder: (context, index) {
                  final flight = flights[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.flight_takeoff,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${flight['airline']} (${flight['flightNumber']})',
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Departure: ${flight['departureTime']} from ${flight['departure']}\n'
                                  'Arrival: ${flight['arrivalTime']} at ${flight['destination']}\n'
                                  'Status: ${flight['status']}',
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to BookingPage with the selected flight
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookingPage(flight: flight),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Book',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
