import 'package:flutter/material.dart';

class AttendanceItem {
  final IconData icon;
  final String title;
  final String time;
  final String status;
  final Color color;

  AttendanceItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.status,
    required this.color,
  });
}