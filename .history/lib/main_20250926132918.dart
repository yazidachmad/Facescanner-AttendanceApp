import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_8/screens/home_screen.dart';
import 'firebase_options.dart';
import '../widgets/login_page.dart';
import '../screens/attendance_history_screen.dart';

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
        fontFamily: 'Tommy',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFF8C61E),
          primary: Color(0xFFF8C61E),
          secondary: Color(0xFF252C37),
          brightness: Brightness.light,
        ).copyWith(
          tertiary: Color(0xff0145f2)
        ),
        useMaterial3: true, // kalau mau pake gaya Material You
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
