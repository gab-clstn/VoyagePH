import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
    await Firebase.initializeApp();
    runApp(const VoyagePHApp());
}

class VoyagePHApp extends StatelessWidget {
  const VoyagePHApp({super.key});

  // VoyagePH brand color (soothing blue with gray undertones)
  static const Color primaryBlue = Color(0xFF4B7B9A);
  static const Color softGray = Color(0xFFF3F6F8);

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => FirebaseAuth.instance,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VoyagePH',
        theme: ThemeData(
          primaryColor: primaryBlue,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
          scaffoldBackgroundColor: softGray,
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Shows login/signup or Home depending on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<FirebaseAuth>(context, listen: false);
    return StreamBuilder<User?>(
      stream: auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const AuthLanding();
        } else {
          return HomeScreen(user: user);
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Landing screen offering Login or Sign Up
class AuthLanding extends StatelessWidget {
  const AuthLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VoyagePH'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.flight_takeoff, size: 96),
            const SizedBox(height: 20),
            const Text(
              'Welcome to VoyagePH',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Book flights across the Philippines — Sign in or create an account.'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              child: const SizedBox(width: double.infinity, child: Center(child: Text('Log In'))),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpScreen()));
              },
              child: const SizedBox(width: double.infinity, child: Center(child: Text('Create account'))),
            ),
          ],
        ),
      ),
    );
  }
}

/// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    final auth = FirebaseAuth.instance;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      await auth.signInWithEmailAndPassword(email: _email.trim(), password: _password);
      // on success, auth state stream will navigate to HomeScreen
      if (mounted) Navigator.of(context).pop(); // close login screen
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                onSaved: (v) => _email = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Password min 6 chars' : null,
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const SizedBox(width: double.infinity, child: Center(child: Text('Log In'))),
                    ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// SIGN UP SCREEN
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _confirm = '';
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });
    final auth = FirebaseAuth.instance;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_password != _confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await auth.createUserWithEmailAndPassword(email: _email.trim(), password: _password);
      // After account created, Firebase automatically signs in.
      if (mounted) Navigator.of(context).pop(); // close sign up
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                onSaved: (v) => _email = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password (min 6)'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Password min 6 chars' : null,
                onSaved: (v) => _password = v ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Confirm password' : null,
                onSaved: (v) => _confirm = v ?? '',
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const SizedBox(width: double.infinity, child: Center(child: Text('Create account'))),
                    ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// HOME SCREEN WITH NAVIGATION (Step 2)
class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({required this.user, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const FlightsPage(),
    const BookingPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.flight), label: 'Flights'),
          NavigationDestination(icon: Icon(Icons.book_online), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// --------------------------- FLIGHTS PAGE ---------------------------
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
    const apiKey = 'd827966fb8b55ac8705e21bdad7fdb59'; // replace again if needed
    final url = Uri.parse(
        'https://api.aviationstack.com/v1/flights?access_key=$apiKey&dep_iata=MNL&limit=10');

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
        title: const Text('Live Flights (Book from MNL)'),
        centerTitle: true,
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
                      final flightNumber =
                          flight['flight']?['iata'] ?? 'N/A';
                      final arrival =
                          flight['arrival']?['airport'] ?? 'Unknown Airport';
                      final status = flight['flight_status'] ?? 'Scheduled';
                      final departureTime =
                          flight['departure']?['scheduled'] ?? 'Unknown';

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.flight_takeoff,
                              color: Colors.blue),
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

// --------------------------- BOOKINGS PAGE ---------------------------
class BookingPage extends StatefulWidget {
  final Map<String, dynamic>? flight;
  const BookingPage({super.key, this.flight});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _notes = TextEditingController();

  DateTime? _travelDate;
  int _numPassengers = 1;
  String _payment = 'GCash';
  String _seatClass = 'Economy';
  String? _seatNumber;
  bool _loading = false;
  double _baseFare = 5000;
  double _computedFare = 5000;

  // Seat map template
  final Map<String, List<String>> _seatMap = {
    'Economy': ['12A', '12B', '13A', '13B', '14A', '14B', '15A', '15B'],
    'Premium Economy': ['10A', '10B', '11A', '11B'],
    'Business': ['4A', '4B', '5A', '5B'],
    'First Class': ['1A', '1B', '2A', '2B'],
  };

  List<String> _availableSeats = [];

  @override
  void initState() {
    super.initState();
    _fetchAvailableSeats();
    _updateFare();
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
      _computedFare = _baseFare * multiplier;
    });
  }

  Future<void> _fetchAvailableSeats() async {
    final bookedSeatsQuery = await FirebaseFirestore.instance
        .collection('bookings')
        .where('flightId', isEqualTo: widget.flight?['id'])
        .get();

    // Collect all seats already taken
    final bookedSeats = bookedSeatsQuery.docs
        .map((doc) => (doc.data()['seatNumber'] ?? '') as String)
        .toList();

    // Compute available seats for current class
    final allSeats = _seatMap[_seatClass] ?? [];
    final available = allSeats.where((s) => !bookedSeats.contains(s)).toList();

    setState(() {
      _availableSeats = available;
      _seatNumber = null; // reset selection
    });
  }

  Future<void> _bookFlight() async {
    if (!_formKey.currentState!.validate() ||
        _travelDate == null ||
        _seatNumber == null) return;

    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user?.uid,
        'flightId': widget.flight?['id'],
        'flightName': widget.flight?['name'],
        'departure': widget.flight?['departure'],
        'destination': widget.flight?['destination'],
        'departureTime': widget.flight?['departureTime'],
        'arrivalTime': widget.flight?['arrivalTime'],
        'passengerName': _name.text,
        'contact': _contact.text,
        'email': _email.text,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Booking Confirmed!')),
        );
        Navigator.pop(context);
      }
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
    _name.dispose();
    _contact.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book Flight: ${widget.flight?['name']}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Passenger Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (v) =>
                    v!.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(_travelDate == null
                    ? 'Select Travel Date'
                    : 'Travel Date: ${_travelDate!.toLocal().toString().split(' ')[0]}'),
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
              Row(
                children: [
                  const Text('Passengers:'),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: _numPassengers,
                    items: [1, 2, 3, 4, 5]
                        .map((n) => DropdownMenuItem(
                            value: n, child: Text(n.toString())))
                        .toList(),
                    onChanged: (v) => setState(() => _numPassengers = v!),
                  ),
                ],
              ),
              const Divider(height: 30),
              const Text('Seating Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              DropdownButtonFormField<String>(
                value: _seatClass,
                decoration: const InputDecoration(labelText: 'Seat Class'),
                items: ['Economy', 'Premium Economy', 'Business', 'First Class']
                    .map((cls) =>
                        DropdownMenuItem(value: cls, child: Text(cls)))
                    .toList(),
                onChanged: (v) async {
                  setState(() {
                    _seatClass = v!;
                    _seatNumber = null;
                  });
                  _updateFare();
                  await _fetchAvailableSeats();
                },
              ),
              DropdownButtonFormField<String>(
                value: _seatNumber,
                decoration: const InputDecoration(labelText: 'Seat Number'),
                items: _availableSeats
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text('Seat $s')))
                    .toList(),
                onChanged: (v) => setState(() => _seatNumber = v),
                validator: (v) =>
                    v == null ? 'Please select a seat number' : null,
              ),
              const SizedBox(height: 12),
              Text('Estimated Fare: ₱${_computedFare.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 30),
              const Text('Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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

// --------------------------- PROFILE PAGE ---------------------------
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              user?.email ?? 'No email',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This profile page will later include personal details and preferences.',
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

