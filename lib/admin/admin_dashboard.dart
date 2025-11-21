import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_drawer.dart';
import 'booking_requests_screen.dart';
import 'cancelled_requests_screen.dart'; // <-- new screen
import 'flight_management.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      drawer: const AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _tile(
                    context,
                    Icons.receipt_long,
                    'Booking Requests',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
                    ),
                  ),
                  _tile(
                    context,
                    Icons.cancel_outlined,
                    'Cancelled Bookings', // <-- new tile
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CancelledRequestsScreen()),
                    ),
                  ),
                  _tile(
                    context,
                    Icons.flight_takeoff,
                    'Flights',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FlightManagementScreen()),
                    ),
                  ),
                  _tile(
                    context,
                    Icons.people_outline,
                    'Users',
                    () => Navigator.of(context).pushNamed('/admin/users'),
                  ),
                  _tile(
                    context,
                    Icons.bar_chart,
                    'Analytics',
                    () => ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Analytics placeholder'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundColor: const Color(0xFF4B7B9A), child: Icon(icon, color: Colors.white)),
              const Spacer(),
              Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
