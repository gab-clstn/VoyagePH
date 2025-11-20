import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';
import 'booking_requests_screen.dart';
import 'flight_management.dart';
import 'user_management.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF4B7B9A);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('VoyagePH Admin', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text('Dashboard', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdminDashboard())),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Booking Requests', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BookingRequestsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.flight_takeoff),
              title: Text('Flights', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlightManagementScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: Text('Users', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserManagementScreen())),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Close', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}