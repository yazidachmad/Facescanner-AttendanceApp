import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/firebase_service.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  const AttendanceSummaryScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  List<AttendanceRecord> _allRecords = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlyRecords();
  }

  Future<void> _loadMonthlyRecords() async {
    setState(() => _isLoading = true);
    try {
      List<AttendanceRecord> allRecords = [];
      int daysInMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        DateTime date =
            DateTime(_selectedMonth.year, _selectedMonth.month, day);
        if (date.isBefore(DateTime.now().add(const Duration(days: 1)))) {
          try {
            List<AttendanceRecord> dayRecords =
                await FirebaseService.getAttendanceRecords(date);
            allRecords.addAll(dayRecords);
          } catch (e) {
            print('Error loading records for $date: $e');
          }
        }
      }
      setState(() {
        _allRecords = allRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1A56DB)),
        ),
        child: child!,
      ),
    );
    if (picked != null &&
        (picked.year != _selectedMonth.year ||
            picked.month != _selectedMonth.month)) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
      _loadMonthlyRecords();
    }
  }

  Map<String, List<AttendanceRecord>> _getRecordsByUser() {
    Map<String, List<AttendanceRecord>> userRecords = {};
    for (AttendanceRecord record in _allRecords) {
      userRecords.putIfAbsent(record.userId, () => []).add(record);
    }
    return userRecords;
  }

  Map<String, int> _getUserAttendanceDays(List<AttendanceRecord> records) {
    Set<String> checkInDays = {}, checkOutDays = {};
    for (var r in records) {
      String key = DateFormat('yyyy-MM-dd').format(r.timestamp);
      if (r.type == AttendanceType.checkIn) checkInDays.add(key);
      else checkOutDays.add(key);
    }
    return {
      'checkInDays': checkInDays.length,
      'checkOutDays': checkOutDays.length,
      'completeDays': checkInDays.intersection(checkOutDays).length,
    };
  }

  Duration _getUserTotalWorkingHours(List<AttendanceRecord> records) {
    Map<String, DateTime?> dailyIn = {}, dailyOut = {};
    for (var r in records) {
      String key = DateFormat('yyyy-MM-dd').format(r.timestamp);
      if (r.type == AttendanceType.checkIn) {
        if (dailyIn[key] == null || r.timestamp.isBefore(dailyIn[key]!))
          dailyIn[key] = r.timestamp;
      } else {
        if (dailyOut[key] == null || r.timestamp.isAfter(dailyOut[key]!))
          dailyOut[key] = r.timestamp;
      }
    }
    Duration total = Duration.zero;
    for (String date in dailyIn.keys) {
      if (dailyOut[date] != null) {
        Duration d = dailyOut[date]!.difference(dailyIn[date]!);
        if (!d.isNegative) total += d;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<AttendanceRecord>> userRecords = _getRecordsByUser();

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                        const Text("Attendance Summary",
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        GestureDetector(
                          onTap: _loadMonthlyRecords,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Month selector
                    GestureDetector(
                      onTap: _selectMonth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('MMMM yyyy').format(_selectedMonth),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                            const Icon(Icons.expand_more_rounded,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overview cards
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  _buildOverviewCard("Total Records",
                      _allRecords.length.toString(), Icons.list_alt_rounded, const Color(0xFF1A56DB)),
                  const SizedBox(width: 10),
                  _buildOverviewCard("Active Users",
                      userRecords.length.toString(), Icons.people_alt_rounded, const Color(0xFF22C55E)),
                  const SizedBox(width: 10),
                  _buildOverviewCard(
                      "Check Ins",
                      _allRecords
                          .where((r) => r.type == AttendanceType.checkIn)
                          .length
                          .toString(),
                      Icons.login_rounded,
                      const Color(0xFFF97316)),
                  const SizedBox(width: 10),
                  _buildOverviewCard(
                      "Check Outs",
                      _allRecords
                          .where((r) => r.type == AttendanceType.checkOut)
                          .length
                          .toString(),
                      Icons.logout_rounded,
                      const Color(0xFFEF4444)),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A56DB)))
                : userRecords.isEmpty
                    ? _buildEmptyState()
                    : _buildUserList(userRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration:
                  BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(title,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: const Icon(Icons.analytics_outlined,
                size: 48, color: Color(0xFF1A56DB)),
          ),
          const SizedBox(height: 16),
          const Text('No attendance data found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text('for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildUserList(Map<String, List<AttendanceRecord>> userRecords) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: userRecords.length,
      itemBuilder: (context, index) {
        String userId = userRecords.keys.elementAt(index);
        List<AttendanceRecord> records = userRecords[userId]!;
        Map<String, int> days = _getUserAttendanceDays(records);
        Duration hours = _getUserTotalWorkingHours(records);
        String name = records.first.userName;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1A56DB),
                radius: 22,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B))),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    _buildChip(
                        '${days['completeDays']} days', const Color(0xFF22C55E)),
                    const SizedBox(width: 6),
                    _buildChip(
                        '${hours.inHours}h ${hours.inMinutes % 60}m',
                        const Color(0xFF1A56DB)),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildStatItem('Check In Days',
                              days['checkInDays'].toString(), const Color(0xFF22C55E)),
                          _buildStatItem('Check Out Days',
                              days['checkOutDays'].toString(), const Color(0xFFEF4444)),
                          _buildStatItem('Complete Days',
                              days['completeDays'].toString(), const Color(0xFF1A56DB)),
                          _buildStatItem('Records',
                              records.length.toString(), const Color(0xFFF97316)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Working Hours:',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Color(0xFF1E293B))),
                            Text(
                              '${hours.inHours}h ${hours.inMinutes % 60}m',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF1A56DB)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style:
                  const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}