// booking_page.dart — Part 1
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

  // Trip
  String _tripType = 'Single Flight'; // Single Flight or Round Trip
  DateTime? _travelDate;
  DateTime? _returnDate;

  // basic booking
  int _numPassengers = 1;
  String _payment = 'GCash';
  String _seatClass = 'Economy';
  bool _loading = false;
  double _baseFare = 2000;
  double _computedFare = 2000;

  // seat map (same for outbound & return)
  final Map<String, List<String>> _seatMap = {
    'Economy': ['12A', '12B', '13A', '13B', '14A', '14B', '15A', '15B'],
    'Premium Economy': ['10A', '10B', '11A', '11B'],
    'Business': ['4A', '4B', '5A', '5B'],
    'First Class': ['1A', '1B', '2A', '2B'],
  };

  // available seats per leg
  List<String> _availableSeatsOutbound = [];
  List<String> _availableSeatsReturn = [];

  // dynamic passenger controllers
  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _contactControllers = [];
  List<TextEditingController> _emailControllers = [];

  // age groups, infant seating, per-passenger seat assignment for both legs
  List<String> _ageGroups = [];
  List<String> _infantSeating = []; // 'On Lap' or 'On Seat'
  List<String?> _seatNumbersOutbound = [];
  List<String?> _seatNumbersReturn = [];

  // user email
  final TextEditingController _userEmailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _baseFare = (widget.flight?['price'] ?? 2000).toDouble();
    _initializePassengerControllers();
    _fetchAvailableSeatsForOutbound();
    _prefillUserEmail();
    _updateFare();
  }

  void _prefillUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmailController.text = user.email ?? '';
      if (_emailControllers.isNotEmpty && _emailControllers[0].text.isEmpty) {
        _emailControllers[0].text = user.email ?? '';
      }
    }
  }

  void _initializePassengerControllers() {
    _nameControllers = List.generate(_numPassengers, (_) => TextEditingController());
    _contactControllers = List.generate(_numPassengers, (_) => TextEditingController());
    _emailControllers = List.generate(_numPassengers, (_) => TextEditingController());
    _ageGroups = List.generate(_numPassengers, (_) => 'Adult');
    _infantSeating = List.generate(_numPassengers, (_) => 'On Seat');
    _seatNumbersOutbound = List<String?>.generate(_numPassengers, (_) => null);
    _seatNumbersReturn = List<String?>.generate(_numPassengers, (_) => null);
  }

  void _updatePassengerControllers(int newCount) {
    // add
    while (_nameControllers.length < newCount) {
      _nameControllers.add(TextEditingController());
      _contactControllers.add(TextEditingController());
      _emailControllers.add(TextEditingController());
      _ageGroups.add('Adult');
      _infantSeating.add('On Seat');
      _seatNumbersOutbound.add(null);
      _seatNumbersReturn.add(null);
    }
    // remove
    while (_nameControllers.length > newCount) {
      _nameControllers.removeLast().dispose();
      _contactControllers.removeLast().dispose();
      _emailControllers.removeLast().dispose();
      _ageGroups.removeLast();
      _infantSeating.removeLast();
      _seatNumbersOutbound.removeLast();
      _seatNumbersReturn.removeLast();
    }
    _updateFare();
  }

  // whether passenger requires seat on a given leg (for infants on lap, no seat required)
  bool _passengerRequiresSeatForLeg(int i, {required bool isReturn}) {
    final age = (i < _ageGroups.length) ? _ageGroups[i] : 'Adult';
    if (age == 'Infant (0-2)') {
      final seating = (i < _infantSeating.length) ? _infantSeating[i] : 'On Seat';
      return seating == 'On Seat';
    }
    return true;
  }

  // seat options for outbound passenger i
  List<String> _seatOptionsForPassengerOutbound(int idx) {
    final taken = _seatNumbersOutbound
        .asMap()
        .entries
        .where((e) => e.key != idx && e.value != null)
        .map((e) => e.value!)
        .toSet();
    final options = <String>{};
    options.addAll(_availableSeatsOutbound);
    if (_seatNumbersOutbound[idx] != null) options.add(_seatNumbersOutbound[idx]!);
    options.removeWhere((s) => taken.contains(s));
    final list = options.toList()..sort();
    return list;
  }

  // seat options for return passenger i
  List<String> _seatOptionsForPassengerReturn(int idx) {
    final taken = _seatNumbersReturn
        .asMap()
        .entries
        .where((e) => e.key != idx && e.value != null)
        .map((e) => e.value!)
        .toSet();
    final options = <String>{};
    options.addAll(_availableSeatsReturn);
    if (_seatNumbersReturn[idx] != null) options.add(_seatNumbersReturn[idx]!);
    options.removeWhere((s) => taken.contains(s));
    final list = options.toList()..sort();
    return list;
  }

  void _updateFare() {
    double multiplier;
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
      default:
        multiplier = 1.0;
    }

    double total = 0.0;
    for (int i = 0; i < _numPassengers; i++) {
      final age = (i < _ageGroups.length) ? _ageGroups[i] : 'Adult';
      if (age == 'Infant (0-2)') {
        // infant: on lap fixed charge, on seat same as adult
        final seating = (i < _infantSeating.length) ? _infantSeating[i] : 'On Seat';
        if (seating == 'On Lap') {
          total += 1000;
        } else {
          total += _baseFare * multiplier;
        }
      } else {
        total += _baseFare * multiplier;
      }
    }

    // round trip doubles fare
    if (_tripType == 'Round Trip') total *= 2;

    setState(() {
      _computedFare = total < 2000 ? 2000 : total;
    });
  }

  // fetch seats for outbound (attempts to filter booked seats if flightId is present)
  Future<void> _fetchAvailableSeatsForOutbound() async {
    try {
      final flightId = widget.flight?['flightId'] ?? widget.flight?['id'];
      if (flightId == null) {
        setState(() {
          _availableSeatsOutbound = _seatMap[_seatClass] ?? [];
        });
        return;
      }

      final bookedSeatsQuery = await FirebaseFirestore.instance
          .collection('bookings')
          .where('flightId', isEqualTo: flightId)
          .get();

      final bookedSeats = bookedSeatsQuery.docs
          .map((doc) => (doc.data()['seatNumber'] ?? '') as String)
          .where((s) => s.isNotEmpty)
          .toList();

      final allSeats = _seatMap[_seatClass] ?? [];
      final available = allSeats.where((s) => !bookedSeats.contains(s)).toList();

      setState(() {
        _availableSeatsOutbound = available;
      });
    } catch (e) {
      // fallback: use full seat list
      setState(() {
        _availableSeatsOutbound = _seatMap[_seatClass] ?? [];
      });
    }
  }

  // fetch seats for return leg.
  // If a returnFlightId is provided in widget.flight['returnFlightId'], it will try to filter booked seats.
  // Otherwise it uses the full seat list for the class.
  Future<void> _fetchAvailableSeatsForReturn() async {
    try {
      final returnFlightId = widget.flight?['returnFlightId'];
      if (returnFlightId != null) {
        final bookedSeatsQuery = await FirebaseFirestore.instance
            .collection('bookings')
            .where('flightId', isEqualTo: returnFlightId)
            .get();

        final bookedSeats = bookedSeatsQuery.docs
            .map((doc) => (doc.data()['seatNumber'] ?? '') as String)
            .where((s) => s.isNotEmpty)
            .toList();

        final allSeats = _seatMap[_seatClass] ?? [];
        final available = allSeats.where((s) => !bookedSeats.contains(s)).toList();

        setState(() {
          _availableSeatsReturn = available;
        });
      } else {
        // No specific return flight id — allow full seat list (inverted route assumed)
        setState(() {
          _availableSeatsReturn = _seatMap[_seatClass] ?? [];
        });
      }
    } catch (e) {
      setState(() {
        _availableSeatsReturn = _seatMap[_seatClass] ?? [];
      });
    }
  }
// booking_page.dart — Part 2 (continued)
  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _contactControllers) c.dispose();
    for (var c in _emailControllers) c.dispose();
    _notes.dispose();
    _userEmailController.dispose();
    super.dispose();
  }

  Future<void> _bookFlight() async {
    if (!_formKey.currentState!.validate() || _travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields')),
      );
      return;
    }

    if (_tripType == 'Round Trip' && _returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return date for round trip')),
      );
      return;
    }

    // ensure each passenger that requires a seat has one for outbound (and return if round trip)
    for (int i = 0; i < _numPassengers; i++) {
      if (_passengerRequiresSeatForLeg(i, isReturn: false) &&
          (_seatNumbersOutbound[i] == null || _seatNumbersOutbound[i]!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select seat for each passenger (outbound)')),
        );
        return;
      }
      if (_tripType == 'Round Trip' &&
          _passengerRequiresSeatForLeg(i, isReturn: true) &&
          (_seatNumbersReturn[i] == null || _seatNumbersReturn[i]!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select seat for each passenger (return)')),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final passengers = List.generate(_numPassengers, (i) {
        return {
          'name': _nameControllers[i].text,
          'contact': _contactControllers[i].text,
          'email': _emailControllers[i].text,
          'ageGroup': _ageGroups[i],
          'infantSeating': _ageGroups[i] == 'Infant (0-2)' ? _infantSeating[i] : '',
          'seatOutbound': _seatNumbersOutbound[i] ?? '',
          'seatReturn': _tripType == 'Round Trip' ? (_seatNumbersReturn[i] ?? '') : '',
        };
      });

      final bookingDoc = {
        'userId': user?.uid,
        'userEmail': _userEmailController.text,
        'tripType': _tripType,
        'flightIdOutbound': widget.flight?['flightId'] ?? widget.flight?['id'],
        'airline': widget.flight?['airline'],
        'flightNumber': widget.flight?['flightNumber'],
        'departure': widget.flight?['departure'],
        'destination': widget.flight?['destination'],
        'departureTime': widget.flight?['departureTime'],
        'arrivalTime': widget.flight?['arrivalTime'],
        'travelDate': _travelDate?.toIso8601String(),
        'returnDate': _tripType == 'Round Trip' ? _returnDate?.toIso8601String() : null,
        'seatClass': _seatClass,
        'fareTotal': _computedFare,
        'paymentMethod': _payment,
        'notes': _notes.text,
        'numPassengers': _numPassengers,
        'passengers': passengers,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').add(bookingDoc);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking flight: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // Styled widgets (kept your original styles)
  Widget _styledContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
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
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        validator: validator,
        decoration: InputDecoration(
          labelText: labelText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4B7B9A), width: 2)),
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
        decoration: InputDecoration(labelText: label, floatingLabelBehavior: FloatingLabelBehavior.auto, border: InputBorder.none),
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
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        title: Text(
          'BOOK FLIGHT: ${widget.flight?['airline'] ?? ''} (${widget.flight?['flightNumber'] ?? ''})',
          style: GoogleFonts.poppins(textStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // user email
              _styledTextField(
                controller: _userEmailController,
                labelText: 'Your Email (login)',
                readOnly: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Login required' : null,
              ),

              // Trip type selector
              _styledDropdown<String>(
                label: 'Trip Type',
                value: _tripType,
                items: ['Single Flight', 'Round Trip'],
                onChanged: (v) async {
                  setState(() {
                    _tripType = v!;
                    if (_tripType == 'Single Flight') {
                      _returnDate = null;
                    }
                    _updateFare();
                  });
                  // fetch return seats as needed
                  if (_tripType == 'Round Trip') {
                    await _fetchAvailableSeatsForReturn();
                  }
                },
              ),

              const SizedBox(height: 8),

              // passenger dynamic fields
              ...List.generate(_numPassengers, (i) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_numPassengers > 1 ? 'Passenger ${i + 1}' : 'Passenger Information', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _styledTextField(controller: _nameControllers[i], labelText: 'Full Name', validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                    _styledTextField(controller: _contactControllers[i], labelText: 'Contact Number', keyboardType: TextInputType.phone, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                    _styledTextField(controller: _emailControllers[i], labelText: 'Email (passenger)', keyboardType: TextInputType.emailAddress, validator: (v) => (v != null && v.contains('@')) ? null : 'Enter valid email'),
                    _styledDropdown<String>(
                      label: 'Age Group',
                      value: _ageGroups[i],
                      items: ['Adult', 'Child (2-12)', 'Infant (0-2)'],
                      onChanged: (v) {
                        setState(() {
                          _ageGroups[i] = v!;
                          if (_ageGroups[i] != 'Infant (0-2)') {
                            _infantSeating[i] = 'On Seat';
                          } else {
                            _infantSeating[i] = 'On Lap';
                          }
                          _updateFare();
                        });
                      },
                    ),
                    if (_ageGroups[i] == 'Infant (0-2)')
                      _styledDropdown<String>(
                        label: 'Infant Seating',
                        value: _infantSeating[i],
                        items: ['On Lap', 'On Seat'],
                        onChanged: (v) {
                          setState(() {
                            _infantSeating[i] = v!;
                            _updateFare();
                          });
                        },
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              }),

              const SizedBox(height: 12),

              // Travel date
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_travelDate == null ? 'Select Travel Date' : 'Travel Date: ${_travelDate!.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 16)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 1)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _travelDate = picked);
                  },
                ),
              ),

              // Return date when round trip
              if (_tripType == 'Round Trip')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_returnDate == null ? 'Select Return Date' : 'Return Date: ${_returnDate!.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 16)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _travelDate != null ? _travelDate!.add(const Duration(days: 1)) : DateTime.now().add(const Duration(days: 1)),
                        firstDate: _travelDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _returnDate = picked);
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Passenger count
              Row(
                children: [
                  const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      child: DropdownButtonFormField<int>(
                        value: _numPassengers,
                        decoration: const InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), filled: true, fillColor: Colors.white),
                        isExpanded: true,
                        items: [1, 2, 3, 4, 5].map((e) => DropdownMenuItem(value: e, child: Center(child: Text(e.toString())))).toList(),
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

              const Text('Seating Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),

              _styledDropdown<String>(
                label: 'Seat Class',
                value: _seatClass,
                items: ['Economy', 'Premium Economy', 'Business', 'First Class'],
                onChanged: (v) async {
                  setState(() {
                    _seatClass = v!;
                    _seatNumbersOutbound = List<String?>.generate(_numPassengers, (_) => null);
                    _seatNumbersReturn = List<String?>.generate(_numPassengers, (_) => null);
                  });
                  _updateFare();
                  await _fetchAvailableSeatsForOutbound();
                  if (_tripType == 'Round Trip') await _fetchAvailableSeatsForReturn();
                },
              ),

              const SizedBox(height: 12),
              const Text('Outbound Seats (Select per passenger)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),

              // Outbound seat selectors
              ...List.generate(_numPassengers, (i) {
                if (!_passengerRequiresSeatForLeg(i, isReturn: false)) return const SizedBox.shrink();
                final options = _seatOptionsForPassengerOutbound(i);
                if (options.isEmpty) {
                  return _styledContainer(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text('No seats available for passenger ${i + 1}', style: const TextStyle(color: Colors.grey))));
                }
                return KeyedSubtree(
                  key: ValueKey('outbound_seat_$i'),
                  child: _styledDropdown<String>(
                    label: 'Seat (Passenger ${i + 1})',
                    value: _seatNumbersOutbound[i],
                    items: options,
                    onChanged: (v) {
                      setState(() {
                        _seatNumbersOutbound[i] = v;
                      });
                    },
                    validator: (v) => (v == null || v.isEmpty) ? 'Select seat' : null,
                  ),
                );
              }),

              const SizedBox(height: 12),

              // Return seats when round trip
              if (_tripType == 'Round Trip') ...[
                const SizedBox(height: 8),
                const Text('Return Seats (Select per passenger)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(_numPassengers, (i) {
                  if (!_passengerRequiresSeatForLeg(i, isReturn: true)) return const SizedBox.shrink();
                  final options = _seatOptionsForPassengerReturn(i);
                  if (options.isEmpty) {
                    return _styledContainer(child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text('No seats available for passenger ${i + 1}', style: const TextStyle(color: Colors.grey))));
                  }
                  return KeyedSubtree(
                    key: ValueKey('return_seat_$i'),
                    child: _styledDropdown<String>(
                      label: 'Return Seat (Passenger ${i + 1})',
                      value: _seatNumbersReturn[i],
                      items: options,
                      onChanged: (v) {
                        setState(() {
                          _seatNumbersReturn[i] = v;
                        });
                      },
                      validator: (v) => (v == null || v.isEmpty) ? 'Select seat' : null,
                    ),
                  );
                }),
              ],

              const SizedBox(height: 12),

              Text('Estimated Fare: ₱${_computedFare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 30),

              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              RadioListTile(title: const Text('GCash'), value: 'GCash', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!)),
              RadioListTile(title: const Text('PayPal'), value: 'PayPal', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!)),
              RadioListTile(title: const Text('Mastercard'), value: 'Mastercard', groupValue: _payment, onChanged: (v) => setState(() => _payment = v!)),

              const SizedBox(height: 12),

              _styledTextField(controller: _notes, labelText: 'Notes (optional)'),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _loading ? null : _bookFlight,
                icon: _loading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.flight_takeoff),
                label: Text(_loading ? 'Booking...' : 'Confirm Booking'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
