// booking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? flight;
  const BookingPage({super.key, this.flight});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  DateTime? _travelDate;
  int _numPassengers = 1;
  String _payment = 'GCash';
  String _seatClass = 'Economy';
  String? _seatNumber;
  bool _loading = false;

  double _baseFare = 2000;
  double _computedFare = 2000;

  final Map<String, List<String>> _seatMap = {
    'Economy': ['12A', '12B', '13A', '13B', '14A', '14B', '15A', '15B'],
    'Premium Economy': ['10A', '10B', '11A', '11B'],
    'Business': ['4A', '4B', '5A', '5B'],
    'First Class': ['1A', '1B', '2A', '2B'],
  };

  List<String> _availableSeats = [];

  // Dynamic passenger controllers
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _contactControllers = [];
  List<TextEditingController> _emailControllers = [];

  // Prefilled logged-in user email
  final TextEditingController _userEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // baseFare from flight if available
    _baseFare = (widget.flight?['price'] ?? 2000).toDouble();
    _initializePassengerControllers();
    _fetchAvailableSeats();
    _updateFare();
    _prefillUserEmail();
  }

  void _prefillUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmailController.text = user.email ?? '';
      // If first passenger email is empty, set it
      if (_emailControllers.isNotEmpty && _emailControllers[0].text.isEmpty) {
        _emailControllers[0].text = user.email ?? '';
      }
    }
  }

  void _initializePassengerControllers() {
    _nameControllers = List.generate(
      _numPassengers,
      (_) => TextEditingController(),
    );
    _contactControllers = List.generate(
      _numPassengers,
      (_) => TextEditingController(),
    );
    _emailControllers = List.generate(
      _numPassengers,
      (_) => TextEditingController(),
    );
    // prefill first passenger email if user logged in will happen in _prefillUserEmail
  }

  void _updatePassengerControllers(int newCount) {
    while (_nameControllers.length < newCount) {
      _nameControllers.add(TextEditingController());
      _contactControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
    }
    while (_nameControllers.length > newCount) {
      _nameControllers.removeLast().dispose();
      _contactControllers.removeLast().dispose();
      _emailControllers.removeLast().dispose();
    }
  }

  void _updateFare() {
    double multiplier = 1.0;
    switch (_seatClass) {
      case 'Economy':
        multiplier = 1.0;
        break;
      case 'Premium Economy':
        multiplier = 1.3;
        break;
      case 'Business':
        multiplier = 1.6;
        break;
      case 'First Class':
        multiplier = 2.0;
        break;
    }

    double fare = _baseFare * multiplier * _numPassengers;

    setState(() {
      _computedFare = fare < 2000 ? 2000 : fare;
    });
  }

  Future<void> _fetchAvailableSeats() async {
    // If there's no flightId in flight data, treat all seats as available
    final flightId = widget.flight?['flightId'];
    if (flightId == null) {
      final allSeats = _seatMap[_seatClass] ?? [];
      setState(() {
        _availableSeats = allSeats;
        _seatNumber = null;
      });
      return;
    }

    final bookedSeatsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('flightId', isEqualTo: flightId)
        .get();

    final bookedSeats = bookedSeatsQuery.docs
        .map((doc) => (doc.data()['seatNumber'] ?? '') as String)
        .toList();

    final allSeats = _seatMap[_seatClass] ?? [];
    final available = allSeats.where((s) => !bookedSeats.contains(s)).toList();

    setState(() {
      _availableSeats = available;
      _seatNumber = null;
    });
  }

  Future<void> _bookFlight() async {
    if (!_formKey.currentState!.validate() ||
        _travelDate == null ||
        _seatNumber == null) {
      // provide feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      // collect passenger data
      List<Map<String, String>> passengers = List.generate(_numPassengers, (i) {
        return {
          'name': _nameControllers[i].text,
          'contact': _contactControllers[i].text,
          'email': _emailControllers[i].text,
        };
      });

      // Build booking document
      final bookingDoc = {
        'userId': user?.uid,
        'userEmail': _userEmailController.text,
        'flightId': widget.flight?['flightId'],
        'airline': widget.flight?['airline'],
        'flightNumber': widget.flight?['flightNumber'],
        'departure': widget.flight?['departure'],
        'destination': widget.flight?['destination'],
        'departureTime': widget.flight?['departureTime'],
        'arrivalTime': widget.flight?['arrivalTime'],
        'duration': widget.flight?['duration'],
        'pricePerGuest': widget.flight?['price'],
        'travelDate': _travelDate!.toIso8601String(),
        'numPassengers': _numPassengers,
        'passengers': passengers,
        'notes': _notes.text,
        'seatClass': _seatClass,
        'seatNumber': _seatNumber,
        'fareTotal': _computedFare,
        'paymentMethod': _payment,
        'status': 'Pending',
        'emailSent': false, // cloud function can update this
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save booking
      final docRef =
          await FirebaseFirestore.instance.collection('bookings').add(bookingDoc);

      // Optional: update seat allocation immediately to avoid race conditions
      // (keep simple here; production should use transactions)
      // Show confirmation screen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationPage(
            bookingId: docRef.id,
            bookingData: bookingDoc,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking flight: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _contactControllers) c.dispose();
    for (var c in _emailControllers) c.dispose();
    _notes.dispose();
    _userEmailController.dispose();
    super.dispose();
  }

  // Styled widgets
  Widget _styledTextField({
    required TextEditingController controller,
    required String labelText,
    bool readOnly = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4B7B9A), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _styledDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BOOK FLIGHT: ${widget.flight?['airline'] ?? ''} (${widget.flight?['flightNumber'] ?? ''})',
          style: GoogleFonts.poppins(textStyle: const TextStyle(color: Colors.white)),
        ),
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // User email (read-only)
              _styledTextField(
                controller: _userEmailController,
                labelText: 'Your Email (login)',
                readOnly: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Login required' : null,
              ),

              const SizedBox(height: 8),

              // passengers dynamic fields
              ...List.generate(_numPassengers, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _numPassengers > 1 ? 'Passenger ${i + 1}' : 'Passenger Information',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    _styledTextField(
                      controller: _nameControllers[i],
                      labelText: 'Full Name',
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    _styledTextField(
                      controller: _contactControllers[i],
                      labelText: 'Contact Number',
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    _styledTextField(
                      controller: _emailControllers[i],
                      labelText: 'Email (passenger)',
                      validator: (v) => (v != null && v.contains('@')) ? null : 'Enter valid email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              // travel date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _travelDate == null
                      ? 'Select Travel Date'
                      : 'Travel Date: ${_travelDate!.toLocal().toIso8601String().split('T')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _travelDate = picked);
                },
              ),

              // passengers count
              Row(
                children: [
                  const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: DropdownButton<int>(
                      value: _numPassengers,
                      items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _numPassengers = v!;
                          _updatePassengerControllers(v);
                          _updateFare();
                        });
                      },
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),
              const Text('Seating Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _styledDropdown<String>(
                label: 'Seat Class',
                value: _seatClass,
                items: ['Economy', 'Premium Economy', 'Business', 'First Class'],
                onChanged: (v) async {
                  setState(() {
                    _seatClass = v!;
                    _seatNumber = null;
                  });
                  _updateFare();
                  await _fetchAvailableSeats();
                },
              ),
              _styledDropdown<String>(
                label: 'Seat Number',
                value: _seatNumber,
                items: _availableSeats,
                onChanged: (v) => setState(() => _seatNumber = v),
                validator: (v) => v == null ? 'Please select a seat' : null,
              ),

              const SizedBox(height: 12),
              Text('Estimated Fare: ₱${_computedFare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),

              const Divider(height: 30),
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              RadioListTile(
                title: const Text('GCash'),
                value: 'GCash',
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v!),
              ),
              RadioListTile(
                title: const Text('PayPal'),
                value: 'PayPal',
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v!),
              ),

              const SizedBox(height: 12),
              _styledTextField(controller: _notes, labelText: 'Notes (optional)'),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _bookFlight,
                  icon: _loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.flight_takeoff),
                  label: Text(_loading ? 'Booking...' : 'Confirm Booking'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Confirmation screen
class BookingConfirmationPage extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  const BookingConfirmationPage({super.key, required this.bookingId, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmed'),
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
            const SizedBox(height: 12),
            Text('Booking ID: $bookingId', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Flight: ${bookingData['airline']} ${bookingData['flightNumber']}'),
            Text('From: ${bookingData['departure']} → To: ${bookingData['destination']}'),
            Text('Date: ${bookingData['travelDate'].toString().split('T')[0]}'),
            Text('Passengers: ${bookingData['numPassengers']}'),
            Text('Seat(s): ${bookingData['seatNumber']}'),
            const SizedBox(height: 12),
            Text('Total Paid: ₱${(bookingData['fareTotal'] ?? 0).toString()}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
