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

      // Center logo (curved overlap)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () => _onItemTapped(1), // Flights
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 3),
            image: const DecorationImage(
              image: AssetImage("lib/assets/app_icon.png"),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // LEFT SIDE
              IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _onItemTapped(0),
              ),

              IconButton(
                icon: Icon(
                  Icons.flight,
                  color: _selectedIndex == 1 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _onItemTapped(1),
              ),

              const SizedBox(width: 20), // gap under center logo
              // RIGHT SIDE
              IconButton(
                icon: Icon(
                  Icons.bookmarks,
                  color: _selectedIndex == 2 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _onItemTapped(2),
              ),

              IconButton(
                icon: Icon(
                  Icons.person,
                  color: _selectedIndex == 3 ? Colors.blue : Colors.grey,
                ),
                onPressed: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
