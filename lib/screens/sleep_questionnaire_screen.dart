import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'device_welcome_screen.dart'; // ✅ NEW IMPORT
import 'device_feedback_screen.dart';
import 'login_screen.dart';
import 'questionnaire_screen.dart';
import 'memory_storage.dart';

class SleepQuestionnaireScreen extends StatefulWidget {
  final Map<String, dynamic>? previousResponses;
  final bool startAtQuestions;

  const SleepQuestionnaireScreen({
    super.key,
    this.previousResponses,
    this.startAtQuestions = false,
  });

  @override
  State<SleepQuestionnaireScreen> createState() =>
      _SleepQuestionnaireScreenState();
}

class _SleepQuestionnaireScreenState extends State<SleepQuestionnaireScreen> {
  bool _showIntro = true;
  final Map<int, String> _responses = {};
  int _currentPage = 0;

  final List<Map<String, dynamic>> _questions = [
    {
      "q": "1. What time did you go to bed last night?",
      "options": [
        "Before 8:00 PM",
        "8:00 PM – 10:00 PM",
        "10:00 PM – 12:00 AM",
        "After 12:00 AM"
      ]
    },
    {
      "q": "2. What time did you wake up this morning?",
      "options": [
        "Before 6:00 AM",
        "6:00 AM – 8:00 AM",
        "8:00 AM – 10:00 AM",
        "After 10:00 AM"
      ]
    },
    {
      "q": "3. How long did it take you to fall asleep last night?",
      "options": [
        "Less than 5 minutes",
        "6–30 minutes",
        "31–60 minutes",
        "More than 60 minutes"
      ]
    },
    {
      "q":
          "4. About how many hours of actual sleep did you get last night (excluding time awake in bed)?",
      "options": [
        "More than 7 hours",
        "6–7 hours",
        "5–6 hours",
        "Less than 5 hours"
      ]
    },
    {
      "q":
          "5. How often did you wake up in the middle of the night or too early in the morning?",
      "options": [
        "Did not wake up at all",
        "Once during the night",
        "Two or three times",
        "Four or more times"
      ]
    },
    {
      "q": "6. Overall, how would you rate your sleep quality last night?",
      "options": ["Very good", "Fairly good", "Fairly bad", "Very bad"]
    },
  ];

  @override
  void initState() {
    super.initState();

    if (widget.startAtQuestions) {
      _showIntro = false;
      _currentPage = 0;
    }

    if (widget.previousResponses != null &&
        widget.previousResponses!["responses"] is Map) {
      final raw = widget.previousResponses!["responses"] as Map;
      raw.forEach((key, value) {
        final idx = _questions.indexWhere((q) => q["q"] == key);
        if (idx != -1 && value != null && value.toString().isNotEmpty) {
          _responses[idx] = value.toString();
        }
      });
    }
  }

  // ---------- PAGE CONTROL ----------
  void _nextPage() {
    if (_showIntro) {
      setState(() => _showIntro = false);
      return;
    }

    final start = _currentPage * 2;
    final end = (start + 2 > _questions.length) ? _questions.length : start + 2;
    final unanswered = List.generate(end - start, (i) => start + i)
        .where((i) => !_responses.containsKey(i))
        .toList();

    if (unanswered.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Incomplete Responses",
              style: GoogleFonts.poppins(
                  color: Colors.black, fontWeight: FontWeight.w700)),
          content: Text(
            "Please answer all questions before continuing.",
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.black)),
            )
          ],
        ),
      );
      return;
    }

    if (_currentPage < 2) {
      setState(() => _currentPage++);
    } else {
      _goToDeviceFeedback();
    }
  }

  void _prevPage() {
    if (_currentPage == 0) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text("Are you sure you want to go back?",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, color: Colors.black)),
          content: Text(
            "Your sleep responses will not be saved.",
            style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.black87)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuestionnaireScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Yes"),
            ),
          ],
        ),
      );
    } else {
      setState(() => _currentPage--);
    }
  }

  // ---------- EXIT DIALOG ----------
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
              backgroundColor: Colors.redAccent,
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

 // ---------- PASS RESPONSES TO DEVICE FEEDBACK ----------
void _goToDeviceFeedback() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final today =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

  // Create a mapping for both text and numeric response
  final Map<String, dynamic> responseMap = {};
  for (int i = 0; i < _questions.length; i++) {
    final q = _questions[i]["q"];
    final selected = _responses[i];
    if (selected != null) {
      final selectedIndex =
          _questions[i]["options"].indexOf(selected); // e.g. 0, 1, 2, 3
      final numericValue = selectedIndex + 1; // convert to 1–4
      responseMap[q] = {
        "text": selected,
        "value": numericValue,
      };
    } else {
      responseMap[q] = {"text": "", "value": null};
    }
  }

  final sleepData = {
    "date": today,
    "responses": responseMap,
  };

  // ✅ Redirect to DeviceWelcomeScreen (with numeric + text responses)
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DeviceWelcomeScreen(
        sleepResponses: sleepData,
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
            onPressed: _prevPage,
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            label: Text(
              "Back",
              style: GoogleFonts.poppins(color: Colors.black, fontSize: 16),
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: ElevatedButton(
            onPressed: _confirmExit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 224, 83, 83),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: const Text("Exit"),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(36, 40, 36, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Sleep Diary",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 38,
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
                const SizedBox(height: 32),
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
                        "You’ll answer 6 short questions about your sleep timing, duration, and quality from last night.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Some questions ask when you went to bed or woke up, while others ask how long or how well you slept.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.8),
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Answer these questions based on your regular sleep cycle.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "After this, you’ll be asked a few short questions about your experience with the sleep device.",
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

  // ---------- MAIN ----------
  @override
  Widget build(BuildContext context) {
    final start = _currentPage * 2;
    final end = (start + 2 > _questions.length) ? _questions.length : start + 2;
    final currentQs = _questions.sublist(start, end);

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
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 20),
                      itemCount: currentQs.length,
                      itemBuilder: (context, i) {
                        final qIndex = start + i;
                        final q = currentQs[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(q["q"],
                                  style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              ...List.generate(
                                q["options"].length,
                                (j) {
                                  final opt = q["options"][j];
                                  final selected = _responses[qIndex] == opt;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _responses[qIndex] = opt),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin:
                                          const EdgeInsets.symmetric(vertical: 4),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 14),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? Colors.black
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.black54, width: 1.0),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            selected
                                                ? Icons.check_circle
                                                : Icons.circle_outlined,
                                            color: selected
                                                ? Colors.white
                                                : Colors.black54,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(opt,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: selected
                                                      ? Colors.white
                                                      : Colors.black,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                )),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 28, left: 20, right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_left_rounded,
                              color: Colors.black, size: 56),
                          onPressed: _prevPage,
                        ),
                        Text("${_currentPage + 1} / 3",
                            style: GoogleFonts.poppins(
                                color: Colors.black.withOpacity(0.8),
                                fontSize: 18,
                                fontWeight: FontWeight.w500)),
                        if (_currentPage == 2)
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
}
