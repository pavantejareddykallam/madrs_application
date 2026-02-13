import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';
import 'memory_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isHoveringLogin = false;
  bool _isHoveringSignup = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showResend = false;

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _loadSavedEmail();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ Load saved email on startup
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  // ✅ Save user email after login
  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedEmail', email);
  }

  // ---------- LOGIN ----------
  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorPopup('Please fill in both fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _showResend = false;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) {
        _showErrorPopup("Login failed. Please try again.");
        return;
      }

      await user.reload();

      // ✅ Check verification
      if (!user.emailVerified) {
        await _auth.signOut();
        setState(() => _showResend = true);
        _showErrorPopup(
            "Please verify your email before logging in. Check your inbox or resend verification.");
        return;
      }

      MemoryStorage.clearMadrs();
      await _saveEmail(_emailController.text.trim());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Invalid credentials. Please try again.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else {
        errorMessage = 'Login failed. Please try again.';
      }

      _showErrorPopup(errorMessage);
    } catch (_) {
      _showErrorPopup('Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------- RESEND VERIFICATION ----------
  Future<void> _resendVerification() async {
    try {
      final user = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await user.user?.sendEmailVerification();
      await _auth.signOut();

      _showErrorPopup(
          "Verification email resent to ${_emailController.text.trim()}.");
    } on FirebaseAuthException catch (e) {
      _showErrorPopup("Failed to resend email: ${e.message}");
    }
  }

  // ---------- FORGOT PASSWORD (email fixed, not editable) ----------
  Future<void> _forgotPasswordDialog() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showErrorPopup(
          "Please enter your email above before requesting a reset link.");
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Reset Password",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "A password reset link will be sent to:",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                email,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _resetPassword(email);
            },
            child: Text(
              "Send Reset Link",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SEND PASSWORD RESET EMAIL ----------
  Future<void> _resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showErrorPopup(
          "Password reset link sent to $email. Please check your inbox or spam folder.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showErrorPopup("No user found with that email.");
      } else {
        _showErrorPopup("Failed to send reset link: ${e.message}");
      }
    }
  }

  // ---------- SHOW SNACKBAR ----------
  void _showErrorPopup(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------- Title ----------
              SlideTransition(
                position: _slideUp,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'MADRS',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 60,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          height: 1.1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 45, top: 4),
                        child: Text(
                          '+ Sleep Diary',
                          style: GoogleFonts.dancingScript(
                            color: Colors.black.withOpacity(0.8),
                            fontSize: 32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // ---------- Email ----------
              _buildTextField(
                controller: _emailController,
                hint: 'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ---------- Password ----------
              _buildPasswordField(),

              // ---------- Forgot Password ----------
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPasswordDialog,
                  child: Text(
                    "Forgot Password?",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ---------- Login Button ----------
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringLogin = true),
                onExit: (_) => setState(() => _isHoveringLogin = false),
                child: AnimatedScale(
                  scale: _isHoveringLogin ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 65, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: _isHoveringLogin ? 10 : 4,
                    ),
                    child: Text(
                      _isLoading ? 'Logging in...' : 'Login',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),

              // ---------- Resend Verification ----------
              if (_showResend) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendVerification,
                  child: Text(
                    "Resend verification email",
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ---------- Sign-Up ----------
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringSignup = true),
                onExit: (_) => setState(() => _isHoveringSignup = false),
                child: AnimatedScale(
                  scale: _isHoveringSignup ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Don’t have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: _isHoveringSignup ? 18 : 16,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Helper Widgets ----------
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: TextInputAction.next,
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: Colors.black54),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Password',
          hintStyle: GoogleFonts.poppins(color: Colors.black54),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }
}
