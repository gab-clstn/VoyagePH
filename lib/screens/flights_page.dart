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

  const FlightsPage({
    super.key,
    this.from,
    this.to,
    this.departureDate,
    DateTime? returnDate,
  });

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

  void generateFlights() {
    final airlines = [
      'Philippine Airlines',
      'Cebu Pacific',
      'AirAsia',
      'PAL Express',
    ];

    // Use the current date to create a seed
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final dailyRandom = Random(seed); // Daily-seeded random generator

    List<Map<String, dynamic>> tempFlights = List.generate(
      5 + dailyRandom.nextInt(5),
      (index) {
        String from;
        String to;

        if (widget.from != null && widget.to != null) {
          from = widget.from!;
          to = widget.to!;
        } else {
          from = locations[dailyRandom.nextInt(locations.length)];
          to = locations[dailyRandom.nextInt(locations.length)];
          while (to == from) {
            to = locations[dailyRandom.nextInt(locations.length)];
          }
        }

        // Random departure hour and minute
        final depHour = 6 + dailyRandom.nextInt(12); // 6AM-5PM
        final depMinute = [0, 15, 30, 45][dailyRandom.nextInt(4)];

        final depDateTime = DateTime(
          today.year,
          today.month,
          today.day,
          depHour,
          depMinute,
        );

        // Random duration 1h-5h + 0,15,30,45 min
        final durationMinutes =
            (1 + dailyRandom.nextInt(5)) * 60 +
            [0, 15, 30, 45][dailyRandom.nextInt(4)];

        final arrDateTime = depDateTime.add(Duration(minutes: durationMinutes));

        String formatTime(DateTime dt) {
          final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
          final minute = dt.minute.toString().padLeft(2, '0');
          final period = dt.hour >= 12 ? 'PM' : 'AM';
          return '$hour:$minute $period';
        }

        final departureTimeStr = formatTime(depDateTime);
        final arrivalTimeStr = formatTime(arrDateTime);

        final hours = durationMinutes ~/ 60;
        final minutes = durationMinutes % 60;
        final durationStr = '${hours}h ${minutes.toString().padLeft(2, '0')}m';

        return {
          'airline': airlines[dailyRandom.nextInt(airlines.length)],
          'flightNumber': 'PH${100 + dailyRandom.nextInt(900)}',
          'departure': from,
          'destination': to,
          'departureTime': departureTimeStr,
          'arrivalTime': arrivalTimeStr,
          'duration': durationStr,
          'status': dailyRandom.nextBool() ? 'Scheduled' : 'Delayed',
          'price': 10399 + dailyRandom.nextInt(4000),
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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Flight booked successfully!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        centerTitle: true,
        elevation: 4,
        title: Text(
          widget.from != null && widget.to != null
              ? '${widget.from} → ${widget.to}'
              : 'FLIGHT SCHEDULES',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: flights.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => generateFlights(),
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: flights.length,
                itemBuilder: (context, index) {
                  final flight = flights[index];
                  return buildFlightCard(flight);
                },
              ),
            ),
    );
  }

  Widget buildFlightCard(Map<String, dynamic> flight) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // Times Row with Airplane in center
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  flight['departureTime'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Column(
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 26,
                    color: Colors.amber[700],
                  ),
                  SizedBox(height: 4),
                  Text(
                    flight['duration'],
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),

              SizedBox(
                width: 60,
                child: Text(
                  flight['arrivalTime'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          SizedBox(height: 4),

          // Locations Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 100,
                child: Text(
                  "Depart – ${flight['departure']}",
                  style: GoogleFonts.poppins(fontSize: 13),
                  softWrap: true,
                ),
              ),
              Container(
                width: 100,
                child: Text(
                  "Arrive – ${flight['destination']}",
                  style: GoogleFonts.poppins(fontSize: 13),
                  softWrap: true,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
          Divider(),

          // Airline & Price
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['airline'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      flight['flightNumber'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "PHP ${flight['price']}.00",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1155CC),
                    ),
                  ),
                  Text(
                    "All-in Fare/guest",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 14),

          // Select Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingPage(flight: flight),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 78, 127, 186),
                padding: EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "BOOK",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
