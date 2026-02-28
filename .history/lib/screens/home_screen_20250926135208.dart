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
            Text(
              "Attendance App",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.tertiary,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: _isReconnecting
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.refresh, size: 16),
                  onPressed: _isReconnecting ? null : _attemptReconnection,
                  tooltip: 'Retry Connection',
                  color: context.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),

      // 🔹 Body
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttendanceCard(),

            const SizedBox(height: 16),

            _buildMenu(context),

            const SizedBox(height: 16),

            _buildTodayAttendance(),

            const SizedBox(height: 16),

            _buildSystemStatus(),
          ],
        ),
      ),
    );
  }

Widget _buildMenu(BuildContext context) {
  final menus = [
    {
      "icon": Icons.history,
      "label": "History",
      "onTap": () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
        );
      }
    },
    {
      "icon": Icons.login,
      "label": "Check In",
      "onTap": () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendanceScreen(mode: AttendanceMode.checkIn),
          ),
        );
      }
    },
    {
      "icon": Icons.logout,
      "label": "Check Out",
      "onTap": () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AttendanceScreen(mode: AttendanceMode.checkOut),
          ),
        );
      }
    },
  ];

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.tertiary, // 🔥 full bar background
    ),
    child: Row(
      children: menus.map((item) {
        return Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: item["onTap"] as VoidCallback,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item["icon"] as IconData,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(height: 8),
                Text(
                  item["label"] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}


  Widget _buildTodayAttendance() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        // 🔥 ini bikin wrap-nya selalu di tengah
        child: Wrap(
          spacing: 20, // jarak horizontal antar box
          runSpacing: 20, // jarak vertikal antar box
          alignment: WrapAlignment.center, // 🔥 align item ke tengah
          children: [
            _buildAttendanceBox(
              icon: Icons.login,
              color: Colors.blue,
              title: "Check In",
              time: "08:30 AM",
              status: "On Time",
            ),
            _buildAttendanceBox(
              icon: Icons.logout,
              color: Colors.red,
              title: "Check Out",
              time: "06:00 PM",
              status: "Go Home",
            ),
            _buildAttendanceBox(
              icon: Icons.lunch_dining,
              color: Colors.orange,
              title: "Break Time",
              time: "12:00 PM",
              status: "Taken",
            ),
            _buildAttendanceBox(
              icon: Icons.calendar_month,
              color: Colors.green,
              title: "Total Days",
              time: "28",
              status: "Working Days",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBox({
    required IconData icon,
    required Color color,
    required String title,
    required String time,
    required String status,
  }) {
    return SizedBox(
      width: 230, // fix biar keliatan grid 2x2
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(status),
          ],
        ),
      ),
    );
  }

  // 🔹 Attendance Card mirip referensi
  Widget _buildAttendanceCard() {
   final now = DateTime.now();

    // format hari (Senin, Selasa, dst)
    final dayName = DateFormat('EEEE').format(now);

    // format tanggal lengkap (24 September 2025 misalnya)
    final fullDate = DateFormat('d MMMM yyyy').format(now);

    // format jam kalau mau
    final time = DateFormat('HH:mm').format(now);

  return Container(
    width: double.infinity,
    margin: EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), // 🔥 padding update
    decoration: BoxDecoration(
      color: context.tertiary,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.symmetric(),
        child:  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         SizedBox(height: 8),
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
        ),

      const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("3", "Normal", Colors.white),
            _buildStatItem("0", "Late", Colors.white),
            _buildStatItem("1", "E-Leave", Colors.white),
            _buildStatItem("0", "Absent", Colors.white),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildSystemStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.tertiary,
        borderRadius: BorderRadius.circular(0),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "System Status",
            style: TextStyle(fontSize: 16, color: Colors.white, fontFamily: 'Tommy'),
          ),
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
                      icon: Icon(Icons.refresh, size: 16, color: context.tertiary,),
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
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // 🔹 Action Card
  Widget _buildActionCard(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
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
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
