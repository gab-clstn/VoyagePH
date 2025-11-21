import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/auth/login_screen.dart'; // <-- add this import

import 'admin_dashboard.dart';
import 'booking_requests_screen.dart';
import 'cancelled_requests_screen.dart';
import 'flight_management.dart';
import 'change_password_screen.dart';
import 'change_email_screen.dart';
import 'change_name_screen.dart';
import 'add_admin_screen.dart';
import 'booking_history_screen.dart'; // <-- import your history screen

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4B7B9A);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: primary),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'VoyagePH Admin',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Dashboard
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: Text('Dashboard', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              ),
            ),

            // Booking Requests
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text('Booking Requests', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingRequestsScreen()),
              ),
            ),

            // Cancelled Bookings
            ListTile(
              leading: const Icon(Icons.cancel_outlined),
              title: Text('Cancelled Bookings', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CancelledRequestsScreen()),
              ),
            ),

            // Flights
            ListTile(
              leading: const Icon(Icons.flight_takeoff),
              title: Text('Flights', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FlightManagementScreen()),
              ),
            ),

            // History
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('History', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingHistoryScreen()),
              ),
            ),

            const Divider(),

            // Change Password
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text('Change Password', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),

            // Change Name
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text('Change Name', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangeNameScreen()),
              ),
            ),

            // Change Email
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text('Change Email', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
              ),
            ),

            // Add Admin
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: Text('Add Admin', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddAdminScreen()),
              ),
            ),

            const Spacer(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: GoogleFonts.poppins(color: Colors.red)),
              onTap: () async {
                // Close drawer first
                Navigator.of(context).pop();

                // Sign out
                await FirebaseAuth.instance.signOut();

                // Navigate to Login screen and remove all previous routes
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),

            // Close Drawer
            ListTile(
              leading: const Icon(Icons.close),
              title: Text('Close', style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
