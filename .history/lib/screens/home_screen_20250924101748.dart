import 'package:flutter/material.dart';
import 'package:flutter_application_8/extension/app_extension.dart';
import 'package:intl/intl.dart';

import 'attendance_screen.dart';
import 'attendance_history_screen.dart';

/// Contoh service biar kode gak error.
/// Sesuaikan sama implementasi asli lo.
class FirebaseService {
  static bool isInitialized = false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isReconnecting = false;
  String _firebaseStatus = "Offline";
  Color _firebaseStatusColor = Colors.red;

  Future<void> _attemptReconnection() async {
    setState(() {
      _isReconnecting = true;
      _firebaseStatus = "Reconnecting...";
      _firebaseStatusColor = Colors.orange;
    });

    await Future.delayed(const Duration(seconds: 2)); // simulasi

    setState(() {
      _isReconnecting = false;
      FirebaseService.isInitialized = true;
      _firebaseStatus = "Online";
      _firebaseStatusColor = Colors.green;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('d MMM').format(now);

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔹 AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false, // hilangin back button default
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Kiri: Icon / Logo
            Icon(Icons.grid_view_rounded,
                color: context.tertiary),

            // Tengah: Tanggal
            Text(
              formattedDate,
              style: TextStyle(
                color: context.tertiary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Kanan: Refresh
            IconButton(
              icon: _isReconnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isReconnecting ? null : _attemptReconnection,
              tooltip: 'Retry Connection',
              color: context.tertiary,
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 🔹 Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.tertiary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.face, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text(
                    'Welcome to Face Attendance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use facial recognition for quick and secure tracking',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionCard(
                  context,
                  Icons.history,
                  "History",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AttendanceHistoryScreen()),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  Icons.login,
                  "Check In",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(
                          mode: AttendanceMode.checkIn,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  context,
                  Icons.logout,
                  "Check Out",
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AttendanceScreen(
                          mode: AttendanceMode.checkOut,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // System Status
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'System Status',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Icon(Icons.info_outline,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 🔹 Firebase row (pakai refresh kalau error)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🔥 Firebase'),
                            if (_isReconnecting) const SizedBox(width: 8),
                            if (_isReconnecting)
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _firebaseStatus,
                              style: TextStyle(
                                color: _firebaseStatusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!FirebaseService.isInitialized &&
                                !_isReconnecting)
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 16),
                                onPressed: _attemptReconnection,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Retry connection',
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _buildStatusItem('📱 Camera', 'Ready', Colors.green),
                    _buildStatusItem('🤖 ML Kit', 'Ready', Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Action Card
  Widget _buildActionCard(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Status Item
  static Widget _buildStatusItem(
      String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(status,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
