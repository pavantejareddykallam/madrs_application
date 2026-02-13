# 🧠 MADRS Application – Sleep Diary & Device Feedback System

The **MADRS Application** is a Flutter-based mobile app integrated with Firebase that allows users to complete:

- MADRS mental health questionnaire  
- Sleep Diary questionnaire  
- Device Feedback survey  

All user responses are securely stored in Firestore and can be exported using a Python script for analysis.

This project demonstrates a complete mobile data collection system with authentication, cloud backend, Excel export, and automated workflows.

---

## 🚀 Features

✅ Firebase Authentication (Login & Signup)  
✅ MADRS Questionnaire (10 questions)  
✅ Sleep Diary (6 questions)  
✅ Device Feedback Survey (3 questions)  
✅ Firestore cloud data storage  
✅ Excel export of all responses  
✅ Firebase Cloud Functions backend  
✅ Python data processing script  

---

## 🧰 Tech Stack

| Layer | Technology |
|------|-----------|
| Mobile App | Flutter + Dart |
| Backend | Firebase (Auth, Firestore, Storage) |
| Automation | Firebase Cloud Functions |
| Data Export | Python |
| UI | Material Design + Google Fonts |

---

## 📱 Application Screens

- Login Screen – User authentication  
- Signup Screen – New account creation  
- Welcome Screen – Greeting after login  
- Sleep Welcome Screen – Intro to sleep section  
- Sleep Questionnaire Screen – Sleep-related responses  
- Questionnaire Screen – MADRS assessment  
- Device Feedback Screen – Experience feedback  
- Final Thank You Screen – Completion confirmation  

---

## 📂 Project Structure (High Level)

madrs_application/
│
├── lib/
│ ├── main.dart
│ ├── firebase_options.dart
│ └── screens/
│
├── functions/ # Firebase Cloud Functions
├── AlluserResponses.py
├── serviceAccountKey.json
├── pubspec.yaml
└── README.md


---

# ▶️ How to Run the madrs_application

This guide walks you through setting up and running the project on a new machine.

---

## 1️⃣ Install Required Software and Dependencies

Make sure the following are installed:

- Visual Studio Code (VS Code)  
- Python 3.9 or later  
- Flutter SDK (latest stable version)  
- Dart SDK (included with Flutter)  
- Java Development Kit (JDK 17)  
- Android Studio with Android SDK  
  - Recommended API Level: 34  

---

### ✅ Add to PATH

Ensure these are added to your system PATH:

- flutter  
- python  

---

How to Run the madrs_application
This document provides concise, step-by-step instructions for setting up and running the madrs_application_aliyousefi project on a new machine.
1. Install Required Software and Dependencies
- Install Visual Studio Code (VS Code).
- Install Python (version 3.9 or later).
- Install Flutter SDK (latest stable version).
- Ensure Dart SDK is included with Flutter.
- Install Java Development Kit (JDK 17).
- Install Android Studio with Android SDK (API level 34 recommended).
- Ensure Flutter and Python are added to system PATH.
- Verify installations by running: flutter doctor and python --version.
2. Steps to Run the Flutter Application
1. Unzip the project folder madrs_application
2. Open the project folder in Visual Studio Code.
3. Open a terminal in the project root directory.
4. Run 'flutter pub get' to install project dependencies.
5. Ensure an Android emulator is running or a physical Android device is connected.
6. Run 'flutter run' to build and launch the application.
7. The app will start on the login screen once the build completes.
3. Running the AlluserResponses.py Script
The AlluserResponses.py script is used to process or analyze user response data.

Steps:
1. Open Command Prompt or Terminal.
2. Navigate to the project root directory.
3. Run the command:
   python AlluserResponses.py

4. Application Screens Overview
- Login Screen: Allows existing users to sign in using Firebase Authentication.
- Signup Screen: Enables new users to create an account.
- Welcome Screen: Displays a welcome message after successful login.
- Sleep Welcome Screen: Introduces the sleep-related questionnaire section.
- Sleep Questionnaire Screen: Collects sleep-related responses from the user.
- Questionnaire Screen: Presents the main MADRS questionnaire.
- Device Feedback Screen: Collects feedback related to device or app usage.
- Final Thank You Screen: Confirms completion and thanks the user.
5. Other Important Components (Backend and Support)
- firebase_options.dart: Contains Firebase project configuration details.
- main.dart: Entry point of the Flutter application.
- Cloud Functions (functions folder): Handles backend logic and Firebase-triggered tasks.
- Firestore Database: Securely stores user responses and authentication data.
- serviceAccountKey.json: Used for server-side Firebase administrative access.


