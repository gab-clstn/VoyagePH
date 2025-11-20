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
  final double _baseFare = 5000;
  double _computedFare = 5000;

  final Map<String, List<String>> _seatMap = {
    'Economy': ['12A', '12B', '13A', '13B', '14A', '14B', '15A', '15B'],
    'Premium Economy': ['10A', '10B', '11A', '11B'],
    'Business': ['4A', '4B', '5A', '5B'],
    'First Class': ['1A', '1B', '2A', '2B'],
  };

  List<String> _availableSeats = [];

  // **Dynamic passenger controllers**
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _contactControllers = [];
  List<TextEditingController> _emailControllers = [];

  @override
  void initState() {
    super.initState();
    _initializePassengerControllers();
    _fetchAvailableSeats();
    _updateFare();
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
  }

  void _updatePassengerControllers(int newCount) {
    // Add controllers if increasing
    while (_nameControllers.length < newCount) {
      _nameControllers.add(TextEditingController());
      _contactControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
    }
    // Remove controllers if decreasing
    while (_nameControllers.length > newCount) {
      _nameControllers.removeLast();
      _contactControllers.removeLast();
      _emailControllers.removeLast();
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
    setState(() {
      _computedFare =
          _baseFare * multiplier * _numPassengers; // multiply by passengers
    });
  }

  Future<void> _fetchAvailableSeats() async {
    final bookedSeatsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('flightId', isEqualTo: widget.flight?['id'])
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
        _seatNumber == null)
      return;

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Collect all passenger info
      List<Map<String, String>> passengers = List.generate(_numPassengers, (i) {
        return {
          'name': _nameControllers[i].text,
          'contact': _contactControllers[i].text,
          'email': _emailControllers[i].text,
        };
      });

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'flightId': widget.flight?['id'],
        'flightName': widget.flight?['name'],
        'departure': widget.flight?['departure'],
        'destination': widget.flight?['destination'],
        'departureTime': widget.flight?['departureTime'],
        'arrivalTime': widget.flight?['arrivalTime'],
        'passengers': passengers,
        'travelDate': _travelDate!.toIso8601String(),
        'numPassengers': _numPassengers,
        'notes': _notes.text,
        'seatClass': _seatClass,
        'seatNumber': _seatNumber,
        'fare': _computedFare,
        'paymentMethod': _payment,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('✅ Booking Confirmed!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking flight: $e')));
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
    super.dispose();
  }

  // Styled TextField / Dropdown container
  Widget _styledContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
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
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4B7B9A), width: 2),
          ),
          suffixIcon: suffixIcon,
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
    return _styledContainer(
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          border: InputBorder.none,
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
            .toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        title: Text(
          'BOOK FLIGHT: ${widget.flight?['airline']} (${widget.flight?['flightNumber']})',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),

        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // back button color
        ),
        elevation: 4,
        shadowColor: Colors.black26,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ...List.generate(_numPassengers, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _numPassengers > 1
                          ? 'Passenger ${i + 1} Information'
                          : 'Passenger Information',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    _styledTextField(
                      controller: _nameControllers[i],
                      labelText: 'Full Name',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    _styledTextField(
                      controller: _contactControllers[i],
                      labelText: 'Contact Number',
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    _styledTextField(
                      controller: _emailControllers[i],
                      labelText: 'Email Address',
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                  ],
                );
              }),
              const SizedBox(height: 12),
              // Travel date
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ), // adds space above and below
                child: ListTile(
                  contentPadding: EdgeInsets
                      .zero, // optional, keeps it aligned with other fields
                  title: Text(
                    _travelDate == null
                        ? 'Select Travel Date'
                        : 'Travel Date: ${_travelDate!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 16),
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
              ),

              // Passenger count dropdown
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Passengers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: DropdownButtonFormField<int>(
                        value: _numPassengers,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        isExpanded: true,
                        items: [1, 2, 3, 4, 5]
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Center(child: Text(e.toString())),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _numPassengers = v!;
                            _updatePassengerControllers(v);
                            _updateFare();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text(
                'Seating Information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              _styledDropdown<String>(
                label: 'Seat Class',
                value: _seatClass,
                items: [
                  'Economy',
                  'Premium Economy',
                  'Business',
                  'First Class',
                ],
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
                validator: (v) =>
                    v == null ? 'Please select a seat number' : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Estimated Fare: ₱${_computedFare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Divider(height: 30),
              const Text(
                'Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
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
              RadioListTile(
                title: const Text('Online Banking (coming soon)'),
                value: 'Online Banking',
                groupValue: _payment,
                onChanged: null,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : _bookFlight,
                icon: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.flight_takeoff),
                label: Text(_loading ? 'Booking...' : 'Confirm Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
