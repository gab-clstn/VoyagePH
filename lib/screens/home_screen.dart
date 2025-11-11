import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'flights_page.dart';
import 'booking_page.dart';
import 'profile_page.dart';

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
          NavigationDestination(
            icon: Icon(Icons.book_online),
            label: 'Bookings',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
