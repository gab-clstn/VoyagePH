import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlightsPage extends StatefulWidget {
  const FlightsPage({super.key});

  @override
  State<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends State<FlightsPage> {
  List<dynamic> flights = [];
  bool loading = true;
  String error = '';

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchFlights();
  }

  Future<void> fetchFlights() async {
    const apiKey =
        'd827966fb8b55ac8705e21bdad7fdb59'; // replace again if needed
    final url = Uri.parse(
      'https://api.aviationstack.com/v1/flights?access_key=$apiKey&dep_iata=MNL&limit=10',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          flights = data['data'] ?? [];
          loading = false;
        });
      } else {
        setState(() {
          error = 'Server responded with ${response.statusCode}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> bookFlight(Map<String, dynamic> flight) async {
    if (user == null) return;

    final bookings = FirebaseFirestore.instance.collection('bookings');
    await bookings.add({
      'userId': user!.uid,
      'airline': flight['airline']?['name'] ?? 'Unknown Airline',
      'flightNumber': flight['flight']?['iata'] ?? 'N/A',
      'arrival': flight['arrival']?['airport'] ?? 'Unknown',
      'departure': flight['departure']?['airport'] ?? 'Unknown',
      'departureTime': flight['departure']?['scheduled'] ?? '',
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
        title: Text(
          'Live Flights (Book from MNL)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text('Error fetching flights:\n$error'))
          : RefreshIndicator(
              onRefresh: fetchFlights,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: flights.length,
                itemBuilder: (context, index) {
                  final flight = flights[index];
                  final airline =
                      flight['airline']?['name'] ?? 'Unknown Airline';
                  final flightNumber = flight['flight']?['iata'] ?? 'N/A';
                  final arrival =
                      flight['arrival']?['airport'] ?? 'Unknown Airport';
                  final status = flight['flight_status'] ?? 'Scheduled';
                  final departureTime =
                      flight['departure']?['scheduled'] ?? 'Unknown';

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.flight_takeoff,
                        color: Colors.blue,
                      ),
                      title: Text(
                        '$airline ($flightNumber)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Destination: $arrival\nDeparture: $departureTime\nStatus: ${status.toUpperCase()}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => bookFlight(flight),
                        child: const Text('Book'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
