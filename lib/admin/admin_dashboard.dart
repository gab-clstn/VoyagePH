import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_drawer.dart';
import 'booking_requests_screen.dart';
import 'cancelled_requests_screen.dart';
import 'flight_management.dart';
import 'admin_booking_history_tab.dart'; // <-- import the history screen

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
                    'Cancelled Bookings',
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
                    Icons.history,
                    'Booking History', // <-- new tile
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BookingHistoryTab()),
                    ),
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
