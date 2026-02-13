import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'device_feedback_screen.dart';

class DeviceWelcomeScreen extends StatefulWidget {
  final Map<String, dynamic>? sleepResponses;
  const DeviceWelcomeScreen({super.key, this.sleepResponses});

  @override
  State<DeviceWelcomeScreen> createState() => _DeviceWelcomeScreenState();
}

class _DeviceWelcomeScreenState extends State<DeviceWelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _staggerController;

  late Animation<double> _fadeMain;
  late Animation<Offset> _slideMain;
  late Animation<Color?> _bgColor;
  late Animation<Color?> _textColor;

  // Staggered fade animations
  late Animation<double> _fadeGreeting;
  late Animation<double> _fadeMessage;
  late Animation<double> _fadeMoveTo;
  late Animation<double> _fadeFeedbackTitle;

  @override
  void initState() {
    super.initState();

    // 🌗 Smooth transition white → black
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    );

    _slideMain = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _fadeMain = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    );

    _bgColor = ColorTween(
      begin: Colors.white,
      end: Colors.black,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _textColor = ColorTween(
      begin: Colors.black,
      end: Colors.white,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );

    // ✨ Separate controller for staggered text fade-ins
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _fadeGreeting = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
    );

    _fadeMessage = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.25, 0.55, curve: Curves.easeIn),
    );

    _fadeMoveTo = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.55, 0.75, curve: Curves.easeIn),
    );

    _fadeFeedbackTitle = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    // After animation completes, navigate to Device Feedback
    _mainController.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 900),
            pageBuilder: (_, __, ___) =>
                DeviceFeedbackScreen(sleepResponses: widget.sleepResponses),
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

    _mainController.forward();

    // Start staggered fade-ins after 1s
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgColor,
      builder: (context, child) {
        final color = _textColor.value ?? Colors.black;
        return Scaffold(
          backgroundColor: _bgColor.value ?? Colors.white,
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Background watermark
              Opacity(
                opacity: 0.07,
                child: Image.asset(
                  'assets/images/brain.png',
                  width: MediaQuery.of(context).size.width * 0.8,
                  fit: BoxFit.contain,
                  color: color.withOpacity(0.1),
                ),
              ),

              // Texts with staggered fade
              Center(
                child: FadeTransition(
                  opacity: _fadeMain,
                  child: SlideTransition(
                    position: _slideMain,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _fadeGreeting,
                          child: Text(
                            "Great job!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dancingScript(
                              color: color,
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: color.withOpacity(0.25),
                                  offset: const Offset(0, 3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeTransition(
                          opacity: _fadeMessage,
                          child: Text(
                            "You've successfully completed the\nSleep Diary section.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: color.withOpacity(0.95),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 35),

                        FadeTransition(
                          opacity: _fadeMoveTo,
                          child: Text(
                            "Now, let's move to",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: color.withOpacity(0.85),
                              fontSize: 24,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        FadeTransition(
                          opacity: _fadeFeedbackTitle,
                          child: Text(
                            "Device Feedback",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: color,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                              shadows: [
                                Shadow(
                                  color: color.withOpacity(0.25),
                                  offset: const Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
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
