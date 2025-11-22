import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Color get _primary => const Color.fromARGB(255, 11, 66, 121);

  Future<void> _openMailClient({
    required String to,
    required String subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {'subject': subject, if (body != null) 'body': body},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchContactUs(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final body =
        'Hello VoyagePH team,\n\nUser: ${user?.email ?? 'unknown'}\nUID: ${user?.uid ?? 'unknown'}\n\n';
    await _openMailClient(
      to: 'support@voyageph.example',
      subject: 'VoyagePH Support',
      body: body,
    );
    if (context.mounted) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ContactUsScreen()));
    }
  }

  Future<void> _showHolidays(BuildContext context) async {
    final now = DateTime.now();
    final holidays = _philippineHolidays(now.year);
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Philippine Holidays',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: holidays.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final h = holidays[i];
                      final d = h['date'] as DateTime;
                      return ListTile(
                        leading: const Icon(Icons.flag_outlined),
                        title: Text(h['name'], style: GoogleFonts.poppins()),
                        subtitle: Text('${d.month}/${d.day}/${d.year}'),
                        onTap: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                h['name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              content: Text(
                                'Date: ${d.month}/${d.day}/${d.year}\n\n${h['notes'] ?? ''}',
                                style: GoogleFonts.poppins(),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _philippineHolidays(int year) {
    return [
      {'date': DateTime(year, 1, 1), 'name': "New Year's Day"},
      {
        'date': DateTime(year, 3, 8),
        'name': "EDSA Revolution Anniversary",
        'notes': '',
      },
      {'date': DateTime(year, 4, 9), 'name': "Araw ng Kagitingan", 'notes': ''},
      {'date': DateTime(year, 5, 1), 'name': "Labor Day"},
      {'date': DateTime(year, 6, 12), 'name': "Independence Day"},
      {'date': DateTime(year, 12, 25), 'name': "Christmas Day"},
      {'date': DateTime(year, 12, 30), 'name': "Rizal Day"},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? '';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primary,
        centerTitle: true,
        title: Text(
          'PROFILE & SETTINGS',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ACCOUNT",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isEmpty ? "User Name" : displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? "No email",
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Basic Information navigates to edit screen (now supports name & email)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text("Basic Information", style: GoogleFonts.poppins()),
              subtitle: Text(
                "Manage your account details",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
            ),

            // Security actions moved under Account / Basic area (not under FAQ & Resources)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text("Change Password", style: GoogleFonts.poppins()),
              subtitle: Text(
                "Send password reset email or change now",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => ResetPasswordScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                "Delete Account",
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
              subtitle: Text(
                "Request deletion via email or delete now (requires password)",
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeleteAccountScreen()),
              ),
            ),

            const SizedBox(height: 15),
            Text(
              "INFORMATION",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text("Philippine Holidays", style: GoogleFonts.poppins()),
              onTap: () => _showHolidays(context),
            ),

            ListTile(
              leading: const Icon(Icons.headset_mic_outlined),
              title: Text("Contact Us", style: GoogleFonts.poppins()),
              onTap: () => _launchContactUs(context),
            ),
            const SizedBox(height: 15),
            Text(
              "FAQ & RESOURCES",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: Text("Terms and Conditions", style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const TermsScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text("About Us", style: GoogleFonts.poppins()),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutUsScreen())),
            ),

            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted)
                  Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout),
              label: Text(
                "Log out",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 46, 100, 155),
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

// Generic simple info screen for Terms / About / Contact placeholders
class SimpleInfoScreen extends StatelessWidget {
  final String title;
  final String content;
  const SimpleInfoScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.poppins(fontSize: 15)),
        ),
      ),
    );
  }
}

// Contact Us screen (simple)
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'CONTACT US',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Email',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'support@voyageph.example',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              'You can also send us a message using your mail app.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'support@voyageph.example',
                  queryParameters: {'subject': 'Support Request'},
                );
                if (await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary),
              child: Text('Open Mail App', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}

// About Us screen
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'ABOUT VOYAGEPH',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'VoyagePH helps you find and book flights across the Philippines. '
            'Our mission is to make travel easier and more accessible for everyone. '
            'You can browse flights, compare prices, and book directly from our app.',
            style: GoogleFonts.poppins(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// Terms & Conditions screen
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'TERMS & CONDITIONS',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            'Terms and Conditions\n\n'
            'Welcome to VoyagePH! By accessing or using our services, you agree to the following:\n\n'
            '• Acceptance of Terms: By using this app, you agree to be bound by these Terms and Conditions.\n\n'
            '• Use of Service:\n'
            '  - Use the app only for lawful purposes.\n'
            '  - Provide accurate and current information.\n\n'
            '• Account Responsibility:\n'
            '  - Keep your account credentials confidential.\n'
            '  - All activity under your account is your responsibility.\n\n'
            '• Privacy: Your personal information is handled in accordance with our Privacy Policy.\n\n'
            '• Intellectual Property: All content and features are property of VoyagePH. Do not copy or distribute without permission.\n\n'
            '• Prohibited Conduct:\n'
            '  - No illegal activities.\n'
            '  - Do not attempt unauthorized access.\n\n'
            '• Termination: Accounts may be suspended or terminated for violating these terms.\n\n'
            '• Limitation of Liability: The app is provided "as is" and VoyagePH is not liable for damages resulting from use.\n\n'
            '• Changes to Terms: Updated terms will be effective upon posting.\n\n'
            '• Governing Law: These terms are governed by the laws of [Your Country/State].',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}

// Reset Password screen with themed UI
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _emailCtrl.text = user?.email ?? '';
  }

  Future<void> _sendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _message = 'Enter an email');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(
        () =>
            _message = 'Password reset email sent. Check your inbox or Gmail.',
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'RESET PASSWORD',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Send a password reset email. Open your mail client to confirm.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            if (_message != null)
              Text(_message!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendReset,
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      child: Text('Send Reset', style: GoogleFonts.poppins()),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// Delete Account screen with options: email request or immediate delete (requires password)
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _deleteNow() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _message = 'No signed in user.');
      return;
    }

    final pw = _pwCtrl.text;
    if (pw.isEmpty) {
      setState(() => _message = 'Enter your password to confirm deletion.');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return; // User cancelled

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: pw,
      );
      await user.reauthenticateWithCredential(cred);
      await user.delete();

      if (mounted) {
        setState(() => _message = 'Account deleted.');
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      Navigator.pushReplacementNamed(context, '/login');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'DELETE ACCOUNT',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request account deletion via email (recommended) or delete now (requires re-entering password).',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),

            Text(
              'Delete now (requires password)',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_message != null)
              Text(_message!, style: GoogleFonts.poppins(color: Colors.red)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _deleteNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Delete Account Now',
                      style: GoogleFonts.poppins(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// EditProfilePage extended: first name, last name, email change (email change requires reauth)
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? '';
    final parts = name.split(' ');
    _firstCtrl.text = parts.isNotEmpty ? parts.first : '';
    _lastCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _emailCtrl.text = user?.email ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user');

      // Update display name
      final displayName = '${_firstCtrl.text.trim()} ${_lastCtrl.text.trim()}'
          .trim();
      if (displayName.isNotEmpty) {
        await user.updateDisplayName(displayName);
      }

      // If email changed, attempt email update (requires reauth)
      final newEmail = _emailCtrl.text.trim();
      if (newEmail.isNotEmpty && newEmail != user.email) {
        // prompt for password to reauth
        final pw = await _askPassword();
        if (pw == null) throw Exception('Reauthentication cancelled');
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: pw,
        );
        await user.reauthenticateWithCredential(cred);

        // After await/reauth the analyzer can't assume 'user' is non-null;
        // re-read currentUser and use that non-null instance for updateEmail.
        // Option A: explicit non-null User variable
        final User? current = FirebaseAuth.instance.currentUser;
        if (current == null)
          throw Exception('User not available after reauthentication');
        final User u = current;
        await u.reload();

        // Option B (shorter): directly call with non-null assertion
        // await FirebaseAuth.instance.currentUser!.updateEmail(newEmail);
        // await FirebaseAuth.instance.currentUser!.reload();
      } else {
        await user.reload();
      }

      setState(() => _message = 'Profile updated.');
    } on FirebaseAuthException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askPassword() async {
    final ctrl = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Password', style: GoogleFonts.poppins()),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Current Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text),
            child: Text('Confirm', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        centerTitle: true,
        title: Text(
          'EDIT PROFILE',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstCtrl,
                    decoration: const InputDecoration(labelText: 'First name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter first name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter last name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(_message!, style: GoogleFonts.poppins(color: Colors.green)),
            const SizedBox(height: 12),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text('Save', style: GoogleFonts.poppins()),
                  ),
          ],
        ),
      ),
    );
  }
}

// Remove GmailPreviewScreen class and replace with a richer in-app email UI
class InAppEmailScreen extends StatelessWidget {
  final String from;
  final String to;
  final String subject;
  final String body;
  final String actionLink;

  const InAppEmailScreen({
    super.key,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.actionLink,
  });

  Future<void> _openLink(BuildContext context) async {
    final uri = Uri.tryParse(actionLink);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color.fromARGB(255, 11, 66, 121);
    return Scaffold(
      appBar: AppBar(
        title: Text('Message — VoyagePH', style: GoogleFonts.poppins()),
        backgroundColor: primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // message header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary,
                  child: Text(
                    'V',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: $from',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'To: ${to.isEmpty ? "(not specified)" : to}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // message body card with CTA
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            body,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // prominent CTA that looks like an in-email button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _openLink(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Reset your password',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you did not request this, ignore this message.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // footer actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Close', style: GoogleFonts.poppins()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    // open actual Gmail web/inbox search for the subject
                    final gmail = Uri.parse(
                      'https://mail.google.com/mail/u/0/#search/${Uri.encodeComponent(subject)}',
                    );
                    if (await canLaunchUrl(gmail))
                      await launchUrl(
                        gmail,
                        mode: LaunchMode.externalApplication,
                      );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primary),
                  child: Text('Open in Gmail', style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
