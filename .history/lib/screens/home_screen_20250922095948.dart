import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'attendance_history_screen.dart';
import 'attendance_summart_screen.dart';
import '../widgets/daily_summary_widget.dart';
import '../services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'attendance_screen.dart';
import 'attendance_history_screen.dart';
import '../services/firebase_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String _firebaseStatus = 'Initializing...';
  Color _firebaseStatusColor = Colors.orange;
  Map<String, dynamic> _syncStatus = {};
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() {
        _isLoading = true;
        _firebaseStatus = 'Initializing Firebase...';
        _firebaseStatusColor = Colors.orange;
      });

      // Initialize Firebase Service (handles offline mode gracefully)
      await FirebaseService.initialize();

      // Get detailed sync status
      _syncStatus = FirebaseService.getSyncStatus();

      setState(() {
        _isLoading = false;
        _updateFirebaseStatus();
      });

      // Test connection in background
      _testConnectionInBackground();
    } catch (e) {
      print('Error initializing services: $e');
      setState(() {
        _isLoading = false;
        _firebaseStatus = 'Initialization Error';
        _firebaseStatusColor = Colors.red;
      });
    }
  }

  void _updateFirebaseStatus() {
    if (FirebaseService.hasPermissionError) {
      _firebaseStatus = 'Permission Denied';
      _firebaseStatusColor = Colors.red;
    } else if (FirebaseService.isInitialized) {
      _firebaseStatus = 'Online';
      _firebaseStatusColor = Colors.green;
    } else if (FirebaseService.isOfflineMode) {
      _firebaseStatus = 'Offline Mode';
      _firebaseStatusColor = Colors.orange;
    } else {
      _firebaseStatus = 'Disconnected';
      _firebaseStatusColor = Colors.red;
    }
  }

  Future<void> _testConnectionInBackground() async {
    // Wait a bit for initialization to complete
    await Future.delayed(const Duration(seconds: 2));

    if (mounted && !FirebaseService.isInitialized) {
      bool connectionResult = await FirebaseService.testConnection();

      if (mounted) {
        setState(() {
          _syncStatus = FirebaseService.getSyncStatus();
          _updateFirebaseStatus();
        });

        if (connectionResult) {
          _showSnackBar('Connection restored!', Colors.green);
        }
      }
    }
  }

  Future<void> _attemptReconnection() async {
    setState(() {
      _isReconnecting = true;
      _firebaseStatus = 'Reconnecting...';
      _firebaseStatusColor = Colors.blue;
    });

    try {
      bool success = await FirebaseService.attemptReconnection();

      setState(() {
        _isReconnecting = false;
        _syncStatus = FirebaseService.getSyncStatus();
        _updateFirebaseStatus();
      });

      if (success) {
        _showSnackBar('Reconnection successful!', Colors.green);
      } else {
        _showSnackBar(
          'Reconnection failed. Check your internet connection.',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _isReconnecting = false;
        _updateFirebaseStatus();
      });
      _showSnackBar('Reconnection error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSyncStatusDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sync Status Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusRow(
                  'Initialized',
                  _syncStatus['initialized']?.toString() ?? 'false',
                ),
                _buildStatusRow(
                  'Offline Mode',
                  _syncStatus['offlineMode']?.toString() ?? 'false',
                ),
                _buildStatusRow(
                  'Permission Error',
                  _syncStatus['hasPermissionError']?.toString() ?? 'false',
                ),
                _buildStatusRow(
                  'Local Records',
                  _syncStatus['localRecordsCount']?.toString() ?? '0',
                ),
                _buildStatusRow(
                  'Firebase Apps',
                  _syncStatus['firebaseAppsCount']?.toString() ?? '0',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Local Records:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_syncStatus['localRecordsCount'] ?? 0} records stored locally',
                ),
                if (_syncStatus['localRecordsCount'] != null &&
                    _syncStatus['localRecordsCount'] > 0)
                  const Text(
                    'These will sync when connection is restored.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!FirebaseService.isInitialized)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _attemptReconnection();
                },
                child: const Text('Retry Connection'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Now = DateTime.now();
    final formattedDate = DateFormat('d, MMMM').format(Now);

    return Scaffold(
  appBar: AppBar(
        automaticallyImplyLeading: false, // biar gak ada back button default
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Kiri: Logo atau Icon
            Icon(Icons.grid_view_rounded, color: Colors.white),

            // Tengah: Tanggal
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Kanan: Icon lain
            Icon(Icons.access_time_rounded, color: Colors.white),
          ],
        ),
        backgroundColor: Theme.of(context), // warna AppBar
        elevation: 0,
      ),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing services...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(Icons.face, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to Face Attendance',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use facial recognition for quick and secure attendance tracking',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          Container(
  margin: const EdgeInsets.symmetric(vertical: 24),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      // History
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AttendanceHistoryScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.history, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text('History', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
      ),

      const SizedBox(width: 12),

      // Check In
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AttendanceScreen(mode: AttendanceMode.checkIn),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.login, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
             Text('Check In', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
      ),

      const SizedBox(width: 12),

      // Check Out
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const AttendanceScreen(mode: AttendanceMode.checkOut),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text('Check Out', style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
        ),
      ),
    ],
  ),
),


          // Enhanced Status Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'System Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: _showSyncStatusDialog,
                        tooltip: 'Show detailed status',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Firebase Status with reconnect button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('🔥 Firebase'),
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

                  _buildStatusItem('📱 Camera', 'Ready', Colors.green),
                  _buildStatusItem('🤖 ML Kit', 'Ready', Colors.green),

                  // Show local records count if any
                  if (_syncStatus['localRecordsCount'] != null &&
                      _syncStatus['localRecordsCount'] > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.storage,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_syncStatus['localRecordsCount']} records stored locally',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
