import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn(
          clientId:
              '542232190217-5q8oic8c0la6283qk076ovpdhn78k4jf.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        )
      : GoogleSignIn(
          serverClientId:
              '542232190217-5q8oic8c0la6283qk076ovpdhn78k4jf.apps.googleusercontent.com',
        );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      // Firebase email/password login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password,
      );

      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check if user exists in admins collection
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // Admin found
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          }
        } else {
          if (mounted) Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      await userCredential.user?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Check admins collection
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (adminSnapshot.docs.isNotEmpty) {
          // Admin found
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          }
        } else {
          // Normal user: pop login
          if (mounted) Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() => _error = "Sign in failed. Check internet or try again.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Password reset email sent to $email",
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Failed to send reset email";
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Please check your connection";
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _email);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Reset Password",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Enter your email address and we'll send you a password reset link.",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              Navigator.of(context).pop(); // Close dialog
              await _sendPasswordResetEmail(email);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B7B9A),
              foregroundColor: Colors.white,
            ),
            child: Text(
              "Send Reset Link",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledTextField({
    required String label,
    required bool obscureText,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    Widget? suffixIcon,
    TextInputType? keyboardType,
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
                                  "Log In",
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Center(
                                  child: Icon(
                                    Icons.person_pin,
                                    size: 90,
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
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
                                        obscureText: _obscure,
                                        validator: (v) =>
                                            (v == null || v.length < 6)
                                            ? 'Min 6 characters'
                                            : null,
                                        onSaved: (v) => _password = v ?? '',
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                          onPressed: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      if (_error != null)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            _error!,
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: _loading
                                              ? null
                                              : _forgotPassword,
                                          child: Text(
                                            "Forgot Password?",
                                            style: GoogleFonts.poppins(
                                              color: primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: _loading
                                              ? null
                                              : _signInWithGoogle,
                                          icon: Image.asset(
                                            'assets/images/google.png',
                                            height: 24,
                                          ),
                                          label: Text(
                                            "Sign in with Google",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF4B7B9A),
                                              width: 1.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
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
                                                        vertical: 16,
                                                      ),
                                                ),
                                                child: Text(
                                                  "Log In",
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
