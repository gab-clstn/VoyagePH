// booking_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? flight;
  final DateTime? travelDate;
  final DateTime? returnDate;
  final Map<String, dynamic>? returnFlight;

  const BookingPage({
    super.key,
    this.flight,
    this.travelDate,
    this.returnDate,
    this.returnFlight,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _notes = TextEditingController();

  DateTime? _travelDate;
  DateTime? _returnDate;

  int _adults = 1;
  int _children = 0;
  int _infants = 0;

  String _payment = 'GCash';
  String _seatClass = 'Economy';
  bool _loading = false;

  double _baseFare = 2000;
  double _computedFare = 2000;

  final Map<String, List<String>> _seatMap = {
    'Economy': [
      '12A',
      '12B',
      '12C',
      '12D',
      '13A',
      '13B',
      '13C',
      '13D',
      '14A',
      '14B',
      '14C',
      '14D',
    ],
    'Premium Economy': ['10A', '10B', '10C', '10D', '11A', '11B', '11C', '11D'],
    'Business': ['4A', '4B', '4C', '4D', '5A', '5B', '5C', '5D'],
    'First Class': ['1A', '1B', '2A', '2B'],
  };

  List<String> _availableSeats = [];
  List<String> _bookedSeats = [];

  List<TextEditingController> _nameControllers = [];
  List<TextEditingController> _contactControllers = [];
  List<TextEditingController> _emailControllers = [];
  List<String> _ageGroups = [];
  List<String> _infantSeating = [];
  List<String?> _seatNumbers = [];

  int get _totalPassengers => _adults + _children + _infants;

  @override
  void initState() {
    super.initState();
    _travelDate = widget.travelDate;
    _returnDate = widget.returnDate;
    _baseFare = widget.flight?['price']?.toDouble() ?? 2000;

    _rebuildPassengerLists(preserveValues: false);
    _fetchAvailableSeats();
    _updateFare();
  }

  void _rebuildPassengerLists({bool preserveValues = true}) {
    final oldNames = List<TextEditingController>.from(_nameControllers);
    final oldContacts = List<TextEditingController>.from(_contactControllers);
    final oldEmails = List<TextEditingController>.from(_emailControllers);
    final oldInfantSeating = List<String>.from(_infantSeating);
    final oldSeats = List<String?>.from(_seatNumbers);

    final newCount = _totalPassengers;

    _nameControllers = List.generate(newCount, (i) {
      if (preserveValues && i < oldNames.length) return oldNames[i];
      return TextEditingController();
    });

    _contactControllers = List.generate(newCount, (i) {
      if (preserveValues && i < oldContacts.length) return oldContacts[i];
      return TextEditingController();
    });

    _emailControllers = List.generate(newCount, (i) {
      if (preserveValues && i < oldEmails.length) return oldEmails[i];
      return TextEditingController();
    });

    _ageGroups = List.generate(newCount, (i) => _roleForIndex(i));

    _infantSeating = List.generate(newCount, (i) {
      if (preserveValues && i < oldInfantSeating.length)
        return oldInfantSeating[i];
      return _ageGroups[i] == 'Infant (0-2)' ? 'On Lap' : 'On Seat';
    });

    _seatNumbers = List.generate(newCount, (i) {
      if (preserveValues && i < oldSeats.length) return oldSeats[i];
      return null;
    });

    setState(() {});
  }

  String _roleForIndex(int index) {
    if (index < _adults) return 'Adult';
    if (index < _adults + _children) return 'Child (2-12)';
    return 'Infant (0-2)';
  }

  bool _passengerRequiresSeat(int i) {
    final age = _ageGroups[i];
    if (age == 'Infant (0-2)') {
      return _infantSeating[i] == 'On Seat';
    }
    return true;
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
    for (int i = 0; i < _totalPassengers; i++) {
      if (_ageGroups[i] == 'Infant (0-2)') {
        if (_infantSeating[i] == 'On Lap') {
          total += 1000;
        } else {
          total += _baseFare * multiplier;
        }
      } else {
        total += _baseFare * multiplier;
      }
    }

    setState(() {
      _computedFare = total < 2000 ? 2000 : total;
    });
  }

  // ------------------------------------------------------------
  // FIX: Rejected bookings no longer block seats
  // ------------------------------------------------------------
  Future<void> _fetchAvailableSeats() async {
    final bookedSeatsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('flightId', isEqualTo: widget.flight?['id'])
        .where('status', whereIn: ['Pending', 'Approved']) // <--- FIX
        .get();

    final bookedSeats = bookedSeatsQuery.docs
        .map((doc) => (doc.data()['seatNumber'] ?? '') as String)
        .toList();

    final normalizedBooked = <String>[];
    for (var bs in bookedSeats) {
      if (bs.trim().isEmpty) continue;
      if (bs.contains(',')) {
        normalizedBooked.addAll(bs.split(',').map((s) => s.trim()));
      } else {
        normalizedBooked.add(bs.trim());
      }
    }

    final allSeats = _seatMap[_seatClass] ?? [];
    final available = allSeats
        .where((s) => !normalizedBooked.contains(s))
        .toList();

    setState(() {
      _bookedSeats = normalizedBooked;
      _availableSeats = available;
      _seatNumbers = List<String?>.generate(_totalPassengers, (_) => null);
    });
  }

  Future<String?> _openSeatPickerModal(BuildContext context, int passengerIdx) {
    final seatList = _seatMap[_seatClass] ?? [];

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Pick seat for Passenger ${passengerIdx + 1} — ${_ageGroups[passengerIdx]}',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: seatList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, i) {
                final seat = seatList[i];
                final takenByBooked = _bookedSeats.contains(seat);
                final takenByOther = _seatNumbers.asMap().entries.any(
                  (e) => e.key != passengerIdx && e.value == seat,
                );
                final isTaken = takenByBooked || takenByOther;
                final isSelected = _seatNumbers[passengerIdx] == seat;

                return GestureDetector(
                  onTap: isTaken ? null : () => Navigator.of(context).pop(seat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isTaken
                            ? Colors.red.shade400
                            : (isSelected
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade400),
                        width: isSelected ? 2.4 : 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      seat,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isTaken ? Colors.red.shade700 : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bookFlight() async {
    if (!_formKey.currentState!.validate() || _travelDate == null) {
      if (_travelDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a travel date')),
        );
      }
      return;
    }

    for (int i = 0; i < _totalPassengers; i++) {
      if (_passengerRequiresSeat(i) &&
          (_seatNumbers[i] == null || _seatNumbers[i]!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select seat for all passengers'),
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      List<Map<String, String>> passengers = List.generate(_totalPassengers, (
        i,
      ) {
        return {
          'name': _nameControllers[i].text,
          'contact': _contactControllers[i].text,
          'email': _emailControllers[i].text,
          'ageGroup': _ageGroups[i],
          'infantSeating': _ageGroups[i] == 'Infant (0-2)'
              ? _infantSeating[i]
              : '',
          'seatNumber': _seatNumbers[i] ?? '',
        };
      });

      final topLevelSeatString = _seatNumbers
          .where((s) => s != null && s.isNotEmpty)
          .join(',');

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'flightId': widget.flight?['id'],
        'airline': widget.flight?['airline'],
        'flightNumber': widget.flight?['flightNumber'],
        'flightName': widget.flight?['name'],
        'departure': widget.flight?['departure'],
        'destination': widget.flight?['destination'],
        'departureTime': widget.flight?['departureTime'],
        'arrivalTime': widget.flight?['arrivalTime'],
        'passengers': passengers,
        'travelDate': _travelDate!.toIso8601String(),
        'returnDate': widget.returnDate?.toIso8601String(),
        'returnFlight': widget.returnFlight ?? {},
        'numPassengers': _totalPassengers,
        'notes': _notes.text,
        'seatClass': _seatClass,
        'seatNumber': topLevelSeatString,
        'fare': _computedFare,
        'paymentMethod': _payment,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));

        if (user != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            (route) => false,
          );
        }
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
    final flight = widget.flight;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 11, 66, 121),
        title: Text(
          'BOOK FLIGHT: ${flight?['airline']} (${flight?['flightNumber']})',
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (widget.returnFlight != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Round Trip Selected',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Outbound: ${flight?['departure']} → ${flight?['destination']} (${_travelDate?.toLocal().toString().split(' ').first})',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Return: ${widget.returnFlight?['departure']} → ${widget.returnFlight?['destination']} (${_returnDate?.toLocal().toString().split(' ').first})',
                      ),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Passengers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      _countControl(
                        'Adults',
                        _adults,
                        () {
                          setState(() {
                            _adults++;
                            _rebuildPassengerLists();
                            _updateFare();
                          });
                        },
                        () {
                          if (_adults > 1) {
                            setState(() {
                              _adults--;
                              _rebuildPassengerLists();
                              _updateFare();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _countControl(
                        'Children',
                        _children,
                        () {
                          setState(() {
                            _children++;
                            _rebuildPassengerLists();
                            _updateFare();
                          });
                        },
                        () {
                          if (_children > 0) {
                            setState(() {
                              _children--;
                              _rebuildPassengerLists();
                              _updateFare();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _countControl(
                        'Infants',
                        _infants,
                        () {
                          setState(() {
                            _infants++;
                            _rebuildPassengerLists();
                            _updateFare();
                          });
                        },
                        () {
                          if (_infants > 0) {
                            setState(() {
                              _infants--;
                              _rebuildPassengerLists();
                              _updateFare();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ...List.generate(_totalPassengers, (i) {
                final role = _ageGroups[i];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Passenger ${i + 1} — $role',
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final phoneRegExp = RegExp(r'^(09|\+639)\d{9}$');
                        if (!phoneRegExp.hasMatch(v))
                          return 'Enter a valid number';
                        return null;
                      },
                    ),

                    _styledTextField(
                      controller: _emailControllers[i],
                      labelText: 'Email Address',
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),

                    if (role == 'Infant (0-2)')
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

                    _styledContainer(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _seatNumbers[i] == null
                                    ? 'Seat: (not selected)'
                                    : 'Seat: ${_seatNumbers[i]}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _seatNumbers[i] == null
                                      ? Colors.grey[700]
                                      : Colors.black,
                                  fontWeight: _seatNumbers[i] == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!(role == 'Infant (0-2)' &&
                                _infantSeating[i] == 'On Lap'))
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final picked = await _openSeatPickerModal(
                                    context,
                                    i,
                                  );
                                  if (picked != null) {
                                    setState(() => _seatNumbers[i] = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.event_seat,
                                  color: Colors.black87,
                                ),
                                label: const Text(
                                  'Pick Seat',
                                  style: TextStyle(color: Colors.black87),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 12),

              _styledContainer(
                child: InkWell(
                  onTap: widget.travelDate == null
                      ? () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null)
                            setState(() => _travelDate = picked);
                        }
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _travelDate == null
                              ? "Select Travel Date"
                              : "Travel Date: ${_travelDate!.toLocal().toString().split(' ').first}",
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (widget.returnDate != null)
                _styledContainer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Return Date: ${widget.returnDate!.toLocal().toString().split(' ').first}',
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

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
                    _seatNumbers = List<String?>.generate(
                      _totalPassengers,
                      (_) => null,
                    );
                  });
                  _updateFare();
                  await _fetchAvailableSeats();
                },
              ),

              const SizedBox(height: 8),
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
                title: const Text('Mastercard'),
                value: 'Mastercard',
                groupValue: _payment,
                onChanged: (v) => setState(() => _payment = v!),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _loading ? null : _bookFlight,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.flight_takeoff, color: Colors.white),
                label: Text(_loading ? 'Booking...' : 'Confirm Booking'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color.fromARGB(255, 56, 82, 163),
                  disabledBackgroundColor: const Color.fromARGB(
                    255,
                    56,
                    82,
                    163,
                  ).withOpacity(0.5),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countControl(
    String label,
    int value,
    VoidCallback onAdd,
    VoidCallback onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Row(
            children: [
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                value.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}