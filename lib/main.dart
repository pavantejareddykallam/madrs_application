import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ REQUIRED IMPORT
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';

// -------------------------------------------------------------
// 🔔 BACKGROUND FCM HANDLER (Required for notifications)
// -------------------------------------------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Handling a background message: ${message.messageId}");
}

// -------------------------------------------------------------
// 🔔 Save FCM Token to Firestore when logged in
// -------------------------------------------------------------
Future<void> setupPushToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // 🔐 Request permission (important for iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 🔔 Get token
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));
  }

  // 🔁 Update token when refreshed
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({'fcmToken': newToken}, SetOptions(merge: true));
  });
}

// -------------------------------------------------------------
// MAIN
// -------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }

  // 🔔 Set background notification handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MadrsApp());
}

class MadrsApp extends StatelessWidget {
  const MadrsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MADRS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// -------------------------------------------------------------
// AUTH GATE — Automatically routes user on login/logout
// -------------------------------------------------------------
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner during auth check
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User logged in → store push token → go to home screen
        if (snapshot.hasData && snapshot.data != null) {
          setupPushToken(); // 🔔 Save token after login
          return const WelcomeScreen();
        }

        // User not logged in → show login screen
        return const LoginScreen();
      },
    );
  }
}
