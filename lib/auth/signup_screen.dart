import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _firstName = '',
      _lastName = '',
      _email = '',
      _password = '',
      _confirm = '';
  bool _loading = false;
  String? _error;
  bool _obscure1 = true, _obscure2 = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_password != _confirm) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Step 1: Create the user in Firebase Auth
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );

      final user = result.user;

      if (user != null) {
        final displayName = '${_firstName.trim()} ${_lastName.trim()}'.trim();

        if (displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }

        // Step 2: Send verification email
        await user.sendEmailVerification();

        // Step 3: Show verification dialog
        if (mounted) await _showVerificationDialog(user);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showVerificationDialog(User user) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Verify your email'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: const Text(
            'A verification email has been sent to your email address. '
            'Please check your inbox and verify your account.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification email resent.'),
                      ),
                    );
                  }
                } catch (_) {}
              },
              child: const Text('Resend'),
            ),
            TextButton(
              onPressed: () async {
                // Step 4: Check verification status
                await user.reload();
                final u = FirebaseAuth.instance.currentUser;
                if (u != null && u.emailVerified) {
                  // Email verified, account is now active
                  if (mounted) {
                    Navigator.of(ctx).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close signup screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account created successfully!'),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email not verified yet.')),
                    );
                  }
                }
              },
              child: const Text('I have verified'),
            ),
          ],
        );
      },
    );
  }

  Widget _styledTextField({
    required String label,
    required bool obscureText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? initialValue,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4B7B9A), width: 2),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4B7B9A);

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4B7B9A),
                  Color(0xFF2C5F7A),
                  Color(0xFF1A3D52),
                ],
              ),
            ),
          ),

          // GIF overlay
          Positioned.fill(
            child: Image.asset('lib/assets/earth2.gif', fit: BoxFit.cover),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 24,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          elevation: 8,
                          shadowColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Create Account",
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _styledTextField(
                                        label: "First Name",
                                        obscureText: false,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? 'Enter first name'
                                            : null,
                                        onSaved: (v) => _firstName = v ?? '',
                                      ),
                                      _styledTextField(
                                        label: "Last Name",
                                        obscureText: false,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? 'Enter last name'
                                            : null,
                                        onSaved: (v) => _lastName = v ?? '',
                                      ),
                                      _styledTextField(
                                        label: "Email",
                                        obscureText: false,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (v) =>
                                            (v == null || !v.contains('@'))
                                            ? 'Enter valid email'
                                            : null,
                                        onSaved: (v) => _email = v ?? '',
                                      ),
                                      _styledTextField(
                                        label: "Password",
                                        obscureText: _obscure1,
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                            ? 'Min 6 characters'
                                            : null,
                                        onSaved: (v) => _password = v ?? '',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure1
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscure1 = !_obscure1,
                                          ),
                                        ),
                                      ),
                                      _styledTextField(
                                        label: "Confirm Password",
                                        obscureText: _obscure2,
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                            ? 'Min 6 characters'
                                            : null,
                                        onSaved: (v) => _confirm = v ?? '',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure2
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscure2 = !_obscure2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      if (_error != null)
                                        Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      _loading
                                          ? const CircularProgressIndicator()
                                          : SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: _submit,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryBlue,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                ),
                                                child: Text(
                                                  "Create Account",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
