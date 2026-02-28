import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import '../widgets/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Attendance App',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: const Color(0xFFF8C61E),
          secondary: const Color(0xFF252C37),
          brightness: Brightness.light,
        ),
        useMaterial3: true, // kalau mau pake gaya Material You
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
