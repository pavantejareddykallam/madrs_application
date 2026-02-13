import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'login_screen.dart';
import 'sleep_welcome_screen.dart';
import 'memory_storage.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  bool _showIntro = true;
  int _currentPage = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Map<int, double> _responses = {};

  final List<String> _questions = const [
    "To what extent have you felt sad, down, or depressed over the past few days?",
    "How much have you lost interest or pleasure in activities you usually enjoy?",
    "How much have your sleep patterns been disturbed or changed from normal?",
    "How much difficulty have you had concentrating or staying focused?",
    "How often have you felt anxious, tense, or unable to relax?",
    "How much fatigue or lack of energy have you experienced lately?",
    "How much difficulty have you had making everyday decisions?",
    "To what extent have you felt pessimistic or hopeless about the future?",
    "How much has your appetite decreased or changed from your usual level?",
    "How strongly have you felt self-critical, guilty, or worthless?",

  ];

  List<List<String>> get _pagedQuestions {
    final pages = <List<String>>[];
    for (var i = 0; i < _questions.length; i += 3) {
      pages.add(_questions.sublist(
          i, (i + 3 > _questions.length) ? _questions.length : i + 3));
    }
    return pages;
  }

  @override
  void initState() {
    super.initState();
    if (MemoryStorage.hasMadrs) {
      _responses.addAll(MemoryStorage.madrsResponses!);
      _showIntro = true;
      _currentPage = 0;
      setState(() {});
    }
  }

  void _nextPage() {
    if (_showIntro) {
      setState(() => _showIntro = false);
      return;
    }

    final currentQuestions = _pagedQuestions[_currentPage];
    final unanswered = <int>[];
    for (int i = 0; i < currentQuestions.length; i++) {
      final questionIndex = _currentPage * 3 + i;
      if (!_responses.containsKey(questionIndex)) {
        unanswered.add(questionIndex + 1);
      }
    }

    if (unanswered.isNotEmpty) {
      final missed = unanswered.join(', ');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Incomplete Responses",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black)),
          content: Text(
            "Please answer all questions on this page before continuing.\n\nYou missed question(s): $missed.",
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
      return;
    }

    if (_currentPage < _pagedQuestions.length - 1) {
      setState(() => _currentPage++);
    } else {
      MemoryStorage.madrsResponses = Map<int, double>.from(_responses);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SleepWelcomeScreen()),
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) setState(() => _currentPage--);
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Are you sure you want to exit?",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Back",
              style: TextStyle(color: Colors.black),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              MemoryStorage.clearMadrs();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 224, 83, 83),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text("Exit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestions = !_showIntro ? _pagedQuestions[_currentPage] : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _showIntro
            ? _buildIntroPage(context)
            : Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, right: 12),
                      child: ElevatedButton(
                        onPressed: _confirmExit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 224, 83, 83),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text("Exit"),
                      ),
                    ),
                  ),

                  // Questions section
                  Expanded(
                    child: Center(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: currentQuestions.length,
                        itemBuilder: (context, index) {
                          final questionIndex = _currentPage * 3 + index;
                          final question = currentQuestions[index];
                          final double value =
                              _responses.containsKey(questionIndex)
                                  ? (_responses[questionIndex]! + 1.0)
                                  : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Text(
                                  question,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Slider
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 8,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 16),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 22),
                                    activeTrackColor: Colors.black,
                                    inactiveTrackColor:
                                        Colors.black.withOpacity(0.2),
                                    thumbColor: Colors.black,
                                  ),
                                  child: Slider(
                                    value: value.toDouble(),
                                    min: 0.0,
                                    max: 7.0,
                                    divisions: 7,
                                    onChanged: (double v) {
                                      if (v == 0.0) {
                                        setState(() =>
                                            _responses.remove(questionIndex));
                                      } else {
                                        setState(() =>
                                            _responses[questionIndex] =
                                                (v - 1.0));
                                      }
                                    },
                                  ),
                                ),

                                // Scale labels 0–6
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(8, (i) {
                                      if (i == 0) return const SizedBox(width: 24);
                                      return SizedBox(
                                        width: 24,
                                        child: Text(
                                          '${i - 1}',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Navigation bar
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 28, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_currentPage > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_left_rounded,
                                color: Colors.black, size: 56),
                            onPressed: _prevPage,
                          )
                        else
                          const SizedBox(width: 56),
                        Text(
                          "${_currentPage + 1} / ${_pagedQuestions.length}",
                          style: GoogleFonts.poppins(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // ✅ Styled right arrow button same as left, or Next for last page
                        if (_currentPage == _pagedQuestions.length - 1)
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(
                              "Next",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                letterSpacing: 0.8,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_right_rounded,
                                color: Colors.black, size: 56),
                            onPressed: _nextPage,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---------- INTRO PAGE ----------
  Widget _buildIntroPage(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            label: Text(
              "Signout",
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 40, 36, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "MADRS Questionnaire",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Before we begin, here’s what to expect:",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.black.withOpacity(0.9),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "You’ll answer 10 short questions about your recent mood, energy, sleep, and emotional well-being.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Each question is rated on a scale from 0 to 6 to reflect the intensity of your experience.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.8),
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Here’s what the values generally mean:",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "• 0 – No symptoms or normal feelings\n"
                        "• 1–2 – Mild or occasional symptoms\n"
                        "• 3–4 – Noticeable or moderate symptoms\n"
                        "• 5–6 – Severe or constant symptoms",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 46, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                    elevation: 0,
                  ),
                  child: Text(
                    "Start",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
