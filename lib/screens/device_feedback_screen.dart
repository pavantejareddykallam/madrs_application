import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'final_thankyou_screen.dart';
import 'login_screen.dart';
import 'memory_storage.dart';
import 'sleep_questionnaire_screen.dart';

class DeviceFeedbackScreen extends StatefulWidget {
  final Map<String, dynamic>? sleepResponses;
  const DeviceFeedbackScreen({super.key, this.sleepResponses});

  @override
  State<DeviceFeedbackScreen> createState() => _DeviceFeedbackScreenState();
}

class _DeviceFeedbackScreenState extends State<DeviceFeedbackScreen> {
  bool _showIntro = true;
  int _currentPage = 0;
  final Map<int, String> _responses = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _questions = [
    {
      "q":
          "1. Did you notice any sound, vibration, or irritation from the device while you were sleeping?",
      "options": [
        "Not at all – I didn’t notice anything unusual.",
        "Slightly – I may have noticed something briefly, but it didn’t disturb me.",
        "Somewhat – I noticed it a few times but went back to sleep easily.",
        "Clearly – I noticed it several times and was aware it came from the device."
      ]
    },
    {
      "q": "2. Did the sound or vibration disturb your sleep?",
      "options": [
        "Not at all – It didn’t disturb my sleep.",
        "Slightly – I noticed it briefly but it didn’t keep me awake.",
        "Moderately – It disturbed my sleep once or twice.",
        "Strongly – It woke me up several times or made it hard to sleep."
      ]
    },
    {
      "q": "3. Would you like to use the device again tonight or in the future?",
      "options": [
        "Definitely not",
        "Probably not",
        "Not sure",
        "Probably yes",
        "Definitely yes"
      ]
    },
  ];

  // ---------- PAGE CONTROL ----------
  void _nextPage() {
    if (_showIntro) {
      setState(() => _showIntro = false);
      return;
    }

    if (!_responses.containsKey(_currentPage)) {
      _showIncompleteDialog();
      return;
    }

    if (_currentPage < _questions.length - 1) {
      setState(() => _currentPage++);
    } else {
      _submitResponses();
    }
  }

  void _prevPage() {
    if (_showIntro || _currentPage == 0) {
      _goBackToSleep();
    } else {
      setState(() => _currentPage--);
    }
  }

  // ---------- GO BACK ----------
  void _goBackToSleep() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Go back to Sleep Diary?",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.black)),
        content: Text(
          "Your device feedback responses will not be saved.",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SleepQuestionnaireScreen(
                    startAtQuestions: true,
                    previousResponses: widget.sleepResponses,
                  ),
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
  }

  // ---------- DIALOGS ----------
  void _showIncompleteDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Incomplete Response",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w700)),
        content: Text(
          "Please select an answer before continuing.",
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
            child: const Text("Back", style: TextStyle(color: Colors.black)),
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

  // ---------- SUBMIT ----------
  Future<void> _submitResponses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final today =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final time =
          "${now.hour.toString().padLeft(2, '0')}-${now.minute.toString().padLeft(2, '0')}-${now.second.toString().padLeft(2, '0')}";

      final userRef = _firestore.collection("Users").doc(user.uid);

      // ---------- DEVICE FEEDBACK ----------
      final Map<String, dynamic> deviceResponses = {};
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i]["q"];
        final selected = _responses[i];
        if (selected != null) {
          final selectedIndex = _questions[i]["options"].indexOf(selected);
          final numericValue = selectedIndex + 1;
          deviceResponses[q] = {
            "text": selected,
            "value": numericValue,
          };
        } else {
          deviceResponses[q] = {"text": "", "value": null};
        }
      }

      final deviceData = {
        "email": user.email,
        "date": today,
        "time": time,
        "responses": deviceResponses,
        "timestamp": FieldValue.serverTimestamp(),
      };

      await userRef
          .collection("DeviceFeedbackResponses")
          .doc("${today}_$time")
          .set(deviceData);

      // ---------- SLEEP ----------
      if (widget.sleepResponses != null) {
        final sleepMap = widget.sleepResponses!;
        await userRef
            .collection("SleepDiaryResponses")
            .doc("${today}_$time")
            .set({
          ...sleepMap,
          "email": user.email,
          "date": today,
          "time": time,
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      // ---------- MADRS ----------
      if (MemoryStorage.madrsResponses != null &&
          MemoryStorage.madrsResponses!.isNotEmpty) {
        final madrsMap = MemoryStorage.madrsResponses!;
        final madrsQuestions = [
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

        await userRef
            .collection("MADRSResponses")
            .doc("${today}_$time")
            .set({
          "email": user.email,
          "date": today,
          "time": time,
          "responses": {
            for (int i = 0; i < madrsMap.length; i++)
              madrsQuestions[i]: madrsMap[i] ?? "",
          },
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      // =================================================================
      // 🔥 ADD THIS: MARK USER AS "RESPONDED" FOR TODAY IN DailyStatus
      // =================================================================
      await _firestore
          .collection("DailyStatus")
          .doc("${today}_${user.uid}")
          .set({
        "userID": user.uid,
        "date": today,
        "responded": true,
        "status": "responded",
        "timestamp": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // =================================================================

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FinalThankYouScreen()),
      );
    } catch (e) {
      debugPrint("❌ Error submitting feedback: $e");
    }
  }

  // ---------- INTRO ----------
  Widget _buildIntroPage(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 10,
          left: 10,
          child: TextButton.icon(
            onPressed: _goBackToSleep,
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
              backgroundColor: Colors.redAccent,
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
                  "Device Feedback",
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
                        "This short section will ask about your experience with the sleep device you used last night.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "You’ll answer 3 short questions about whether you noticed any sound, vibration, or irritation from the device, whether it affected your sleep, and if you’d consider using it again.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.8),
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Please answer based on your honest experience.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.black.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
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
                          backgroundColor: Colors.redAccent,
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _questions[_currentPage]["q"],
                            style: GoogleFonts.poppins(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(
                            _questions[_currentPage]["options"].length,
                            (j) {
                              final opt = _questions[_currentPage]["options"][j];
                              final selected =
                                  _responses[_currentPage] == opt;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _responses[_currentPage] = opt),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color:
                                        selected ? Colors.black : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.black54, width: 1.2),
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
                                        child: Text(
                                          opt,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: selected
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
                        if (_currentPage == _questions.length - 1)
                          ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical:10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: Text(
                              "Submit",
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
