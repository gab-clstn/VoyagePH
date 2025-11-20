import 'package:flutter/material.dart';
import 'home_page.dart';
import 'flights_page.dart';
import 'package:voyageph/auth/login_screen.dart';

class GuestWrapper extends StatefulWidget {
  const GuestWrapper({super.key});

  @override
  State<GuestWrapper> createState() => _GuestWrapperState();
}

class _GuestWrapperState extends State<GuestWrapper> {
  int _currentIndex = 0;

  // Accessible pages for guest
  final List<Widget> guestPages = const [
    HomePage(),
    FlightsPage(),
  ];

  // Titles for bottom navigation
  final List<String> guestTitles = [
    "Home",
    "Flights",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          guestTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4B7B9A),
        foregroundColor: Colors.white,
      ),

      body: guestPages[_currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4B7B9A),
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flight),
            label: "Flights",
          ),
        ],
      ),

      // Floating button for restricted features
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showLoginRequired(context);
        },
        backgroundColor: const Color(0xFF4B7B9A),
        label: const Text("More Features"),
        icon: const Icon(Icons.lock),
      ),
    );
  }

  // Pop-up when trying to access restricted features
  void _showLoginRequired(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "You need to be logged in to access this feature.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text("Log In"),
          ),
        ],
      ),
    );
  }
}
