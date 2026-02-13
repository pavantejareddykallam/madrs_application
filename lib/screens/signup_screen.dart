import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isHoveringSignup = false;
  bool _isHoveringLogin = false;
  bool _showPasswordHint = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // ---------- SIGNUP FUNCTION ----------
  Future<void> _signup() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showErrorPopup("Please enter your first and last name.");
      return;
    }
    if (pass.length < 6) {
      _showErrorPopup('Password must be at least 6 characters long.');
      return;
    }
    if (pass != confirm) {
      _showErrorPopup('Passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ 1. Create Firebase Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );

      final user = cred.user;
      if (user == null) {
        _showErrorPopup("Account creation failed. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      // ✅ 2. Force refresh before sending verification
      await user.reload();

      // ✅ 3. Send the verification email
      await user.sendEmailVerification();

      // ✅ 4. Assign unique participant ID safely using Firestore transaction
      final usersCollection = _firestore.collection('Users');
      final counterRef = _firestore.collection('Meta').doc('UserCounter');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        int current = snapshot.exists ? snapshot['count'] : 0;
        int newCount = current + 1;
        transaction.set(counterRef, {'count': newCount});
        String participantID = 'P$newCount';

        transaction.set(usersCollection.doc(user.uid), {
          'participantID': participantID,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ Optional: also update "Emails" collection
        transaction.set(
          _firestore.collection('Emails').doc(email.toLowerCase()),
          {
            'uid': user.uid,
            'participantID': participantID,
            'createdAt': FieldValue.serverTimestamp(),
          },
        );
      });

      // ✅ 5. Wait briefly to ensure email dispatch completes
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verification email sent to $email.\nPlease verify before logging in.',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );

      // ✅ 6. Navigate back to Login Screen
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorPopup('Firebase Auth failed: ${e.message}');
    } catch (e) {
      _showErrorPopup('Sign up failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorPopup(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
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
              const SizedBox(height: 40),

              // ---------- First Name ----------
              _buildTextField(_firstNameController, 'First Name'),
              const SizedBox(height: 20),

              // ---------- Last Name ----------
              _buildTextField(_lastNameController, 'Last Name'),
              const SizedBox(height: 20),

              // ---------- Email ----------
              _buildTextField(
                _emailController,
                'Email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // ---------- Password ----------
              _buildPasswordField(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showPasswordHint
                    ? Padding(
                        key: const ValueKey('hint'),
                        padding:
                            const EdgeInsets.only(top: 8.0, left: 6, right: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password should have at least 6 characters.',
                            style: GoogleFonts.poppins(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(key: ValueKey('empty'), height: 0),
              ),
              const SizedBox(height: 20),

              // ---------- Confirm Password ----------
              _buildConfirmPasswordField(),
              const SizedBox(height: 36),

              // ---------- Sign Up Button ----------
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringSignup = true),
                onExit: (_) => setState(() => _isHoveringSignup = false),
                child: AnimatedScale(
                  scale: _isHoveringSignup ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 65, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: _isHoveringSignup ? 10 : 4,
                    ),
                    child: Text(
                      _isLoading ? 'Creating...' : 'Sign Up',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ---------- Redirect to Login ----------
              MouseRegion(
                onEnter: (_) => setState(() => _isHoveringLogin = true),
                onExit: (_) => setState(() => _isHoveringLogin = false),
                child: AnimatedScale(
                  scale: _isHoveringLogin ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 180),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: _isHoveringLogin ? 18 : 16,
                        ),
                        children: [
                          TextSpan(
                            text: "Login",
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
  Widget _buildTextField(TextEditingController controller, String hint,
      {TextInputType? keyboardType}) {
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
        textInputAction: TextInputAction.next,
        onChanged: (value) =>
            setState(() => _showPasswordHint = value.isNotEmpty),
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

  Widget _buildConfirmPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Confirm Password',
          hintStyle: GoogleFonts.poppins(color: Colors.black54),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    );
  }
}
