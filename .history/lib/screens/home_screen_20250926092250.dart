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
      backgroundColor: Colors.white,

      // 🔹 AppBar custom
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Attendance App",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: appbar,
              ),
            ),

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

            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),

      // 🔹 Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attendance / Week Card
            _buildAttendanceCard(),

            const SizedBox(height: 16),

            // Action Grid (History, Check In, Check Out)
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
                        builder: (_) => const AttendanceHistoryScreen(),
                      ),
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

            const SizedBox(height: 16),

            // Next Lesson Card (statis dulu)
            _buildNextLessonCard(),

            const SizedBox(height: 16),

            // System Status
            _buildSystemStatus(),
          ],
        ),
      ),
    );
  }

  // 🔹 Attendance Card mirip referensi
  Widget _buildAttendanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tertiary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Attendance / Week",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                onPressed: () {},
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
        
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("3", "Normal", context.tertiary ),
              _buildStatItem("0", "Late", context.tertiary ),
              _buildStatItem("1", "E-Leave", context.tertiary ),
              _buildStatItem("0", "Absent", context.tertiary ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Next Lesson Card
  Widget _buildNextLessonCard() {
  // ambil waktu sekarang
  final now = DateTime.now();

  // format hari (Senin, Selasa, dst)
  final dayName = DateFormat('EEEE').format(now); 

  // format tanggal lengkap (24 September 2025 misalnya)
  final fullDate = DateFormat('d MMMM yyyy').format(now);

  // format jam kalau mau
  final time = DateFormat('HH:mm').format(now);

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.tertiary,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          dayName, // contoh: Wednesday
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "$fullDate · $time",
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    ),
  );
}

  // 🔹 Announcement Card
  

  // 🔹 System Status
  Widget _buildSystemStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tertiary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("System Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Firebase row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("🔥 Firebase"),
                  if (_isReconnecting) const SizedBox(width: 8),
                  if (_isReconnecting)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
                  if (!FirebaseService.isInitialized && !_isReconnecting)
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
          _buildStatusItem("📱 Camera", "Ready", Colors.green),
          _buildStatusItem("🤖 ML Kit", "Ready", Colors.green),
        ],
      ),
    );
  }

  // 🔹 Reusable Stats
  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.blue,
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
  static Widget _buildStatusItem(String label, String status, Color color) {
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
