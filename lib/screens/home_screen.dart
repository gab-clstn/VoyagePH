import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'flights_page.dart';
import 'profile_page.dart';
import 'my_bookings_page.dart';
import 'home_page.dart';

class HomeScreen extends StatefulWidget {
  final User user;
  const HomeScreen({required this.user, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _hasBooking = false;

  final List<Widget> _pages = [
    const HomePage(),
    const FlightsPage(),
    const MyBookingsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserBooking();
  }

  Future<void> _checkUserBooking() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: widget.user.uid)
        .limit(1)
        .get();
    if (mounted) {
      setState(() {
        _hasBooking = snapshot.docs.isNotEmpty;
      });
    }
  }

  void _onItemTapped(int index) async {
    if (index == 2 && !_hasBooking) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bookings yet. Please book a flight first.'),
        ),
      );
      return;
    }

    if (index == 2) {
      await _checkUserBooking();
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        alignment: AlignmentDirectional.topCenter,
        clipBehavior: Clip.none,
        children: [
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.flight), label: 'Flights'),
              NavigationDestination(icon: Icon(Icons.bookmarks), label: 'My Bookings'),
              NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
          Positioned(
            top: -15, // Adjust to overlap on nav bar
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1; // For example, navigate to Flights
                });
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Optional background
                  border: Border.all(color: Colors.blue, width: 3),
                  image: const DecorationImage(
                    image: AssetImage('lib/assets/app_icon.png'), // replace with your file path
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
