import 'package:flutter/material.dart';
import 'package:raimu/extension/app_extension.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/attendance_record.dart';
import '../services/firebase_service.dart';
import '../widgets/export_report_widget.dart';
import 'attendance_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  List<AttendanceRecord> _attendanceRecords = [];
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() => _isLoading = true);
    try {
      List<AttendanceRecord> records =
          await FirebaseService.getAttendanceRecords(_selectedDate);
      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load attendance records: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A56DB)),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadAttendanceRecords();
    }
  }

  List<AttendanceRecord> _getFilteredRecords() {
    if (_selectedFilter == 'All') return _attendanceRecords;
    AttendanceType filterType = _selectedFilter == 'Check In'
        ? AttendanceType.checkIn
        : AttendanceType.checkOut;
    return _attendanceRecords.where((r) => r.type == filterType).toList();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Attendance Data'),
        content: const SizedBox(
            width: double.maxFinite, child: ExportReportWidget()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showRecordDetails(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: record.type == AttendanceType.checkIn
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                record.type == AttendanceType.checkIn
                    ? Icons.login_rounded
                    : Icons.logout_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              record.type == AttendanceType.checkIn
                  ? 'Check In Details'
                  : 'Check Out Details',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User', record.userName),
              _buildDetailRow(
                  'Time', DateFormat('HH:mm:ss').format(record.timestamp)),
              _buildDetailRow('Date',
                  DateFormat('EEEE, dd MMM yyyy').format(record.timestamp)),
              if (record.confidence != null)
                _buildDetailRow('Confidence',
                    '${(record.confidence! * 100).toStringAsFixed(1)}%'),
              if (record.photoPath != null &&
                  File(record.photoPath!).existsSync()) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(record.photoPath!),
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                      fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  String _getAttendanceSummary() {
    List<AttendanceRecord> filteredRecords = _getFilteredRecords();
    int checkInCount =
        filteredRecords.where((r) => r.type == AttendanceType.checkIn).length;
    int checkOutCount =
        filteredRecords.where((r) => r.type == AttendanceType.checkOut).length;
    return 'Check In: $checkInCount  |  Check Out: $checkOutCount';
  }

  @override
  Widget build(BuildContext context) {
    List<AttendanceRecord> filteredRecords = _getFilteredRecords();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A56DB), Color(0xFF1E90FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const Text("Attendance History",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        PopupMenuButton<String>(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.more_vert,
                                color: Colors.white, size: 18),
                          ),
                          onSelected: (value) {
                            if (value == 'export') _showExportDialog();
                            if (value == 'refresh') _loadAttendanceRecords();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                                value: 'refresh',
                                child: Row(children: [
                                  Icon(Icons.refresh, size: 18),
                                  SizedBox(width: 8),
                                  Text('Refresh')
                                ])),
                            const PopupMenuItem(
                                value: 'export',
                                child: Row(children: [
                                  Icon(Icons.file_download, size: 18),
                                  SizedBox(width: 8),
                                  Text('Export Data')
                                ])),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Hero Banner
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Track Check In\n& Check Out Hours",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const AttendanceScreen(
                                            mode: AttendanceMode.checkIn))),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3))
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timer_rounded,
                                          color: Color(0xFF1A56DB), size: 18),
                                      SizedBox(width: 6),
                                      Text("Check In",
                                          style: TextStyle(
                                              color: Color(0xFF1A56DB),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                        Image.asset('assets/images/hand.png',
                            width: 130, height: 110, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Time Summary Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeSlot("Clock In", "08:00 AM", const Color(0xFF1A56DB)),
                Container(width: 1, height: 36, color: Colors.grey[200]),
                _buildTimeSlot(
                    "Break Time", "12:00 PM", const Color(0xFFF97316)),
                Container(width: 1, height: 36, color: Colors.grey[200]),
                _buildTimeSlot(
                    "Clock Out", "05:00 PM", const Color(0xFFEF4444)),
              ],
            ),
          ),

          // Date + Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: Color(0xFF1A56DB), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B)),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded,
                              color: Colors.grey, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8)
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.expand_more_rounded,
                          color: Colors.grey, size: 18),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B)),
                      items: ['All', 'Check In', 'Check Out']
                          .map((v) =>
                              DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedFilter = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Summary text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Your Attendance",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                Text(_getAttendanceSummary(),
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF1A56DB)))
                : filteredRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildAttendanceList(filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String label, String time, Color color) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(time,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy_rounded,
                size: 48, color: Color(0xFF1A56DB)),
          ),
          const SizedBox(height: 16),
          const Text('No attendance records',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadAttendanceRecords,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56DB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceRecord> records) {
    final topRecords = records.take(3).toList();

    return Column(
      children: [
        if (records.length > 3)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _showAllRecordsDialog(context, records),
                child: const Text("See All",
                    style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1A56DB),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: topRecords.length,
            itemBuilder: (context, index) =>
                _buildAttendanceCard(topRecords[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord record) {
    final isCheckIn = record.type == AttendanceType.checkIn;
    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCheckIn
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
                color: isCheckIn
                    ? const Color(0xFF1A56DB)
                    : const Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCheckIn ? 'Check In' : 'Check Out',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('dd MMMM yyyy').format(record.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(record.timestamp),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCheckIn
                          ? const Color(0xFF1A56DB)
                          : const Color(0xFFEF4444)),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllRecordsDialog(
      BuildContext context, List<AttendanceRecord> records) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.maxFinite,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text("All Records",
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) =>
                      _buildAttendanceCard(records[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}