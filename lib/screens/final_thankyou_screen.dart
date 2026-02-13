import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class FinalThankYouScreen extends StatefulWidget {
  const FinalThankYouScreen({super.key});

  @override
  State<FinalThankYouScreen> createState() => _FinalThankYouScreenState();
}

class _FinalThankYouScreenState extends State<FinalThankYouScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _madrsData;
  Map<String, dynamic>? _sleepData;
  Map<String, dynamic>? _deviceData;

  // ---------------- FETCH ALL RESPONSES ----------------
  Future<void> _fetchAllResponses() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = FirebaseFirestore.instance.collection("Users").doc(user.uid);

      // MADRS Responses
      final madrsSnap = await userDoc
          .collection("MADRSResponses")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      // Sleep Diary Responses
      final sleepSnap = await userDoc
          .collection("SleepDiaryResponses")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      // Device Feedback Responses
      final deviceSnap = await userDoc
          .collection("DeviceFeedbackResponses")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? madrs =
          madrsSnap.docs.isNotEmpty ? madrsSnap.docs.first.data() : null;
      Map<String, dynamic>? sleep =
          sleepSnap.docs.isNotEmpty ? sleepSnap.docs.first.data() : null;
      Map<String, dynamic>? device =
          deviceSnap.docs.isNotEmpty ? deviceSnap.docs.first.data() : null;

      setState(() {
        _madrsData = madrs;
        _sleepData = sleep;
        _deviceData = device;
        _isLoading = false;
      });

      _showTranscriptDialog();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching responses: $e")),
      );
    }
  }

  // ---------------- SHOW TRANSCRIPT DIALOG ----------------
  void _showTranscriptDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "🧾 Your Questionnaire Summary",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              if (_madrsData != null)
                _buildResponseSection(
                  title: "MADRS Assessment",
                  date: _madrsData!["date"] ?? "",
                  responses: _madrsData!["responses"] ?? {},
                  total: _madrsData!["totalScore"],
                ),
              if (_madrsData != null) const SizedBox(height: 20),

              if (_sleepData != null)
                _buildResponseSection(
                  title: "Sleep Diary",
                  date: _sleepData!["date"] ?? "",
                  responses: _sleepData!["responses"] ?? {},
                  total: _sleepData!["totalScore"],
                ),
              if (_sleepData != null) const SizedBox(height: 20),

              if (_deviceData != null)
                _buildResponseSection(
                  title: "Device Feedback",
                  date: _deviceData!["date"] ?? "",
                  responses: _deviceData!["responses"] ?? {},
                  total: _deviceData!["totalScore"],
                ),

              if (_madrsData == null &&
                  _sleepData == null &&
                  _deviceData == null)
                Text(
                  "No questionnaire responses found.",
                  style: GoogleFonts.poppins(
                      color: Colors.white70, fontSize: 16),
                ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 2,
                ),
                child: Text("Close",
                    style: GoogleFonts.poppins(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- BUILD RESPONSE SECTION ----------------
  Widget _buildResponseSection({
    required String title,
    required String date,
    required Map responses,
    required dynamic total,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$title (${date.isEmpty ? 'No date' : date})",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: responses.length,
            separatorBuilder: (_, __) => Divider(
              color: Colors.white.withOpacity(0.1),
              height: 10,
            ),
            itemBuilder: (context, index) {
              final question = responses.keys.elementAt(index);
              final response = responses.values.elementAt(index);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  question,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  response.toString(),
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              );
            },
          ),
          if (total != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total Score: ${total.toString()}",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------- SIGN OUT ----------------
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  // ---------------- MAIN UI ----------------
  @override
  Widget build(BuildContext context) {
    const grayscaleGradient = LinearGradient(
      colors: [Color(0xFF000000), Color(0xFF1C1C1C), Color(0xFF3A3A3A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: grayscaleGradient),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 100),
                const SizedBox(height: 30),
                Text(
                  "Thank You!",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Your responses have been successfully submitted.\nWe appreciate your time and participation!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 50),

                // View transcript button
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchAllResponses,
                  icon: const Icon(Icons.article_rounded, color: Colors.black),
                  label: Text(
                    _isLoading ? "Loading..." : "View My Transcript",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out button
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  label: Text(
                    "Sign Out",
                    style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 38, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
