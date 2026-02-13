import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'questionnaire_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeText;
  late Animation<Offset> _slideText;
  late Animation<Color?> _bgColor;
  late Animation<Color?> _textColor;

  String _firstName = 'there';

  @override
  void initState() {
    super.initState();

    // ⚡ Smooth 4-second transition white → black
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    _slideText = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeText = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    // Background: white → black
    _bgColor = ColorTween(
      begin: Colors.white,
      end: Colors.black,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));

    // Text color: black → white
    _textColor = ColorTween(
      begin: Colors.black,
      end: Colors.white,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, __, ___) => const QuestionnaireScreen(),
            transitionsBuilder: (_, a, __, child) {
              final fade =
                  CurvedAnimation(parent: a, curve: Curves.easeInOutCubic);
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(fade);
              return FadeTransition(
                opacity: fade,
                child: SlideTransition(position: slide, child: child),
              );
            },
          ),
        );
      }
    });

    _loadFirstName();
  }

  Future<void> _loadFirstName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _controller.forward();
        return;
      }

      final snap = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      String? fn = snap.data()?['firstName'] as String?;
      fn ??= user.displayName;
      fn ??= user.email?.split('@').first;
      fn ??= 'there';

      setState(() => _firstName = fn!.trim().isEmpty ? 'there' : fn.trim());
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgColor,
      builder: (context, child) {
        final textColor = _textColor.value ?? Colors.black;
        return Scaffold(
          backgroundColor: _bgColor.value ?? Colors.white,
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Soft translucent background accent (grayscale)
              Opacity(
                opacity: 0.07,
                child: Image.asset(
                  'assets/images/brain.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                  color: textColor.withOpacity(0.08),
                ),
              ),

              // Center animated text
              Center(
                child: FadeTransition(
                  opacity: _fadeText,
                  child: SlideTransition(
                    position: _slideText,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 👋 Friendly greeting
                        Text(
                          'Hi, $_firstName',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dancingScript(
                            color: textColor,
                            fontSize: 54,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: textColor.withOpacity(0.2),
                                offset: const Offset(0, 3),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 🖤 Clean black/white title
                        Text(
                          'Welcome to MADRS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 46,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: textColor.withOpacity(0.25),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
