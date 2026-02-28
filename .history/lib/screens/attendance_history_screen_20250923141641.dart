import 'package:flutter/material.dart';
import 'package:flutter_application_8/extension/app_extension.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/attendance_record.dart';
import '../services/firebase_service.dart';
import '../widgets/export_report_widget.dart';

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
  String _selectedFilter = 'All'; // All, Check In, Check Out

  @override
  void initState() {
    super.initState();
    _loadAttendanceRecords();
  }

  Future<void> _loadAttendanceRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<AttendanceRecord> records =
          await FirebaseService.getAttendanceRecords(_selectedDate);

      setState(() {
        _attendanceRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading attendance records: $e');
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Failed to load attendance records: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceRecords();
    }
  }

  List<AttendanceRecord> _getFilteredRecords() {
    if (_selectedFilter == 'All') {
      return _attendanceRecords;
    }

    AttendanceType filterType = _selectedFilter == 'Check In'
        ? AttendanceType.checkIn
        : AttendanceType.checkOut;

    return _attendanceRecords
        .where((record) => record.type == filterType)
        .toList();
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Attendance Data'),
          content: const SizedBox(
            width: double.maxFinite,
            child: ExportReportWidget(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRecordDetails(AttendanceRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                record.type == AttendanceType.checkIn
                    ? Icons.login
                    : Icons.logout,
                color: record.type == AttendanceType.checkIn
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                record.type == AttendanceType.checkIn
                    ? 'Check In Details'
                    : 'Check Out Details',
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
                  'Time',
                  DateFormat('HH:mm:ss').format(record.timestamp),
                ),
                _buildDetailRow(
                  'Date',
                  DateFormat('EEEE, dd MMM yyyy').format(record.timestamp),
                ),
                if (record.confidence != null)
                  _buildDetailRow(
                    'Confidence',
                    '${(record.confidence! * 100).toStringAsFixed(1)}%',
                  ),
                const SizedBox(height: 16),

                if (record.photoPath != null &&
                    File(record.photoPath!).existsSync())
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Captured Photo:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(record.photoPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (record.faceData != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Face Detection Data:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildFaceDataWidget(record.faceData!),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFaceDataWidget(Map<String, dynamic> faceData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (faceData['boundingBox'] != null)
            Text(
              'Face Size: ${faceData['boundingBox']['width'].toInt()} x ${faceData['boundingBox']['height'].toInt()}',
            ),

          if (faceData['headEulerAngleY'] != null)
            Text(
              'Head Rotation: ${faceData['headEulerAngleY'].toStringAsFixed(1)}°',
            ),

          if (faceData['smilingProbability'] != null)
            Text(
              'Smiling: ${(faceData['smilingProbability'] * 100).toStringAsFixed(1)}%',
            ),

          if (faceData['leftEyeOpenProbability'] != null)
            Text(
              'Left Eye Open: ${(faceData['leftEyeOpenProbability'] * 100).toStringAsFixed(1)}%',
            ),

          if (faceData['rightEyeOpenProbability'] != null)
            Text(
              'Right Eye Open: ${(faceData['rightEyeOpenProbability'] * 100).toStringAsFixed(1)}%',
            ),
        ],
      ),
    );
  }

  String _getAttendanceSummary() {
    List<AttendanceRecord> filteredRecords = _getFilteredRecords();
    int checkInCount = filteredRecords
        .where((r) => r.type == AttendanceType.checkIn)
        .length;
    int checkOutCount = filteredRecords
        .where((r) => r.type == AttendanceType.checkOut)
        .length;

    return 'Check In: $checkInCount, Check Out: $checkOutCount';
  }

  @override
  Widget build(BuildContext context) {
    List<AttendanceRecord> filteredRecords = _getFilteredRecords();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) {
              if (value == 'export') {
                _showExportDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceRecords,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            child: Row(
              children: [
                Text("Attendance"),
                Row(
                  children: [
                    Icon(Icons.history),
                  ],
                )
              ],
            ),
          ),
          // Date and Filter Controltes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.primary,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Selector
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: context.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat(
                                  'EEEE, dd MMM yyyy',
                                ).format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Filter Selector
                Row(
                  children:  [
                    Icon(Icons.filter_list, color: context.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.0, right: 15.0), 
                       child:  DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: ['All', 'Check In', 'Check Out']
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    )
                  ],
                ),

                const SizedBox(height: 8),

                // Summary
                Text(
                  _getAttendanceSummary(),
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading attendance records...'),
                      ],
                    ),
                  )
                : filteredRecords.isEmpty
                ? _buildEmptyState()
                : _buildAttendanceList(filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAttendanceRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<AttendanceRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        AttendanceRecord record = records[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: record.type == AttendanceType.checkIn
                  ? Colors.green
                  : Colors.red,
              child: Icon(
                record.type == AttendanceType.checkIn
                    ? Icons.login
                    : Icons.logout,
                color: Colors.white,
              ),
            ),
            title: Row(
              children: [
                Text(
                  record.type == AttendanceType.checkIn
                      ? 'Check In'
                      : 'Check Out',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (record.type == AttendanceType.checkIn
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('HH:mm:ss').format(record.timestamp),
                    style: TextStyle(
                      color: record.type == AttendanceType.checkIn
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  record.userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat(
                        'dd MMM yyyy, HH:mm:ss',
                      ).format(record.timestamp),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                if (record.confidence != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.verified, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Confidence: ${(record.confidence! * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRecordDetails(record),
          ),
        );
      },
    );
  }
}
