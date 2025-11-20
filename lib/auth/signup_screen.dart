import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '', _confirm = '';
  bool _loading = false;
  String? _error;
  bool _obscure1 = true;
  bool _obscure2 = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (_password != _confirmPassword) {
      setState(() => _error = "Passwords do not match");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openGmail() async {
    final uri = Uri.parse('https://mail.google.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Gmail.')),
        );
      }
    }
  }

  Future<void> _showVerificationDialog(User user) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Verify your email'),
          content: const Text(
            'A verification email has been sent to your email address. '
            'Please open Gmail and confirm to complete account creation.',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  await user.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent.')),
                    );
                  }
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to resend verification.')),
                    );
                  }
                }
              },
              child: const Text('Resend'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await _openGmail();
              },
              child: const Text('Open Gmail'),
            ),
            TextButton(
              onPressed: () async {
                await user.reload();
                final u = FirebaseAuth.instance.currentUser;
                if (u != null && u.emailVerified) {
                  if (mounted) {
                    Navigator.of(ctx).pop(); // close dialog
                    Navigator.of(context).pop(); // close signup screen
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
    required Function(String?) onSaved,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: TextFormField(
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        onSaved: onSaved,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF4B7B9A);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              const SizedBox(height: 20),
              Center(
                child: Icon(Icons.person_add, size: 100, color: primaryBlue),
              ),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // First & Last name fields
                    Row(
                      children: [
                        Expanded(
                          child: _styledTextField(
                            label: "First name",
                            obscureText: false,
                            keyboardType: TextInputType.name,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter first name' : null,
                            onSaved: (v) => _firstName = v?.trim() ?? '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _styledTextField(
                            label: "Last name",
                            obscureText: false,
                            keyboardType: TextInputType.name,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter last name' : null,
                            onSaved: (v) => _lastName = v?.trim() ?? '',
                          ),
                        ),
                      ],
                    ),

                    _styledTextField(
                      label: "Email",
                      obscureText: false,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter valid email'
                          : null,
                      onSaved: (v) => _email = v ?? '',
                    ),
                    _styledTextField(
                      label: "Password",
                      obscureText: _obscure1,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Min 6 characters'
                          : null,
                      onSaved: (v) => _password = v ?? '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure1 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    _styledTextField(
                      label: "Confirm Password",
                      obscureText: _obscure2,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Min 6 characters'
                          : null,
                      onSaved: (v) => _confirm = v ?? '',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure2 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),

                    const SizedBox(height: 16),

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
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                "Sign Up",
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
    );
  }
}
