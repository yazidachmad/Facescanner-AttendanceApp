import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math';

import '../models/attendance_record.dart';
import '../services/firebase_service.dart';
import '../services/camera_service.dart';
import '../services/face_detection_service.dart';
import '../extension/app_extension.dart';

enum AttendanceMode { checkIn, checkOut }

class AttendanceScreen extends StatefulWidget {
  final AttendanceMode mode;
  const AttendanceScreen({Key? key, required this.mode}) : super(key: key);

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  List<Face> _detectedFaces = [];

  final CameraService _cameraService = CameraService();
  final FaceDetectionService _faceDetectionService = FaceDetectionService();

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool get _isCheckIn => widget.mode == AttendanceMode.checkIn;
  Color get _themeColor =>
      _isCheckIn ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
  Color get _themeDark =>
      _isCheckIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _requestCameraPermission();
      await _faceDetectionService.initialize();
      await _initializeCamera();
    } catch (e) {
      print('Error initializing services: $e');
      _showErrorDialog('Initialization Error', e.toString());
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) throw Exception('Camera permission denied');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController = await _cameraService.initializeCamera();
      await _cameraController!.initialize();
      await _cameraController!.lockCaptureOrientation();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorDialog('Camera Error', 'Failed to initialize camera: $e');
    }
  }

  Future<void> _captureAndProcessImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final imagePath = await CameraService.captureImage(_cameraController!);
      final imageFile = File(imagePath);
      if (!await imageFile.exists())
        throw Exception('Captured image file does not exist');

      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetectionService.detectFaces(inputImage);
      setState(() => _detectedFaces = faces);

      if (faces.isNotEmpty) {
        await _processAttendance(imagePath, faces.first);
      } else {
        _showMessage('No Face Detected',
            'Please ensure your face is clearly visible in the camera.');
      }
    } catch (e) {
      print('Error capturing and processing image: $e');
      _showErrorDialog('Processing Error', e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processAttendance(String imagePath, Face face) async {
    try {
      String recordId = '${DateTime.now().millisecondsSinceEpoch}';
      String userId = 'user_${Random().nextInt(1000)}';
      String userName = 'Employee ${Random().nextInt(100)}';

      double confidence = face.headEulerAngleY != null
          ? (1.0 - (face.headEulerAngleY!.abs() / 90.0))
          : 0.8;

      Map<String, dynamic> faceData = _faceDetectionService.getFaceInfo(face);

      AttendanceRecord record = AttendanceRecord(
        id: recordId,
        userId: userId,
        userName: userName,
        type: _isCheckIn ? AttendanceType.checkIn : AttendanceType.checkOut,
        timestamp: DateTime.now(),
        photoPath: imagePath,
        faceData: faceData,
        confidence: confidence,
      );

      bool success = await FirebaseService.saveAttendanceRecord(record);

      if (success) {
        _showSuccessDialog(record);
      } else {
        _showMessage('Save Failed',
            'Failed to save attendance record. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Attendance Error', e.toString());
    }
  }

  void _showSuccessDialog(AttendanceRecord record) {
    String typeText = _isCheckIn ? 'Check In' : 'Check Out';
    String timeText = DateFormat('HH:mm:ss').format(record.timestamp);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _themeColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    color: _themeColor, size: 40),
              ),
              const SizedBox(height: 16),
              Text('$typeText Successful!',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text('Your attendance has been recorded',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.person_outline_rounded,
                        record.userName, Colors.grey[700]!),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.access_time_rounded, timeText,
                        const Color(0xFF1A56DB)),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.verified_rounded,
                        '${(record.confidence! * 100).toStringAsFixed(1)}% confidence',
                        _themeColor),
                  ],
                ),
              ),
              if (record.photoPath != null &&
                  File(record.photoPath!).existsSync()) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(record.photoPath!),
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK',
                  style: TextStyle(color: Color(0xFF1A56DB))))
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.red)))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetectionService.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized ? _buildCameraView() : _buildLoadingView(),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: const Color(0xFF0F1923),
      child: SafeArea(
        child: Column(
          children: [
            // AppBar area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCheckIn ? 'Check In' : 'Check Out',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                  color: _themeColor, strokeWidth: 3),
            ),
            const SizedBox(height: 20),
            const Text('Initializing camera...',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Setting up face detection',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final screenSize = MediaQuery.of(context).size;
    final camera = _cameraController!.value;
    final previewSize = camera.previewSize;

    if (previewSize == null ||
        previewSize.height == 0 ||
        previewSize.width == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    final scale = max(
      screenSize.width / previewSize.height,
      screenSize.height / previewSize.width,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        Center(
          child: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
        ),

        // Dark overlay top & bottom
        Column(
          children: [
            Container(
              height: screenSize.height * 0.25,
              color: Colors.black.withOpacity(0.55),
            ),
            const Spacer(),
            Container(
              height: screenSize.height * 0.28,
              color: Colors.black.withOpacity(0.7),
            ),
          ],
        ),

        // Face detection overlays
        ..._detectedFaces
            .map((face) => _buildFaceOverlay(face, scale))
            .toList(),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _themeColor, strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text('Processing...',
                      style: TextStyle(
                          color: _themeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Please hold still',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),
          ),

        // Top bar
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _themeColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              _isCheckIn
                                  ? Icons.login_rounded
                                  : Icons.logout_rounded,
                              color: Colors.white,
                              size: 16),
                          const SizedBox(width: 6),
                          Text(_isCheckIn ? 'Check In' : 'Check Out',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.info_outline_rounded,
                          color: Colors.white60, size: 18),
                    ),
                  ],
                ),
              ),

              // Instruction text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Position your face in the frame and tap the button below',
                    style:
                        TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scan frame overlay
        Center(
          child: AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: _ScanFramePainter(
                    color: _detectedFaces.isNotEmpty
                        ? const Color(0xFF22C55E)
                        : _themeColor,
                    progress: _scanAnimation.value),
                child: const SizedBox(width: 220, height: 220),
              );
            },
          ),
        ),

        // Bottom action area
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
            ),
            child: Column(
              children: [
                // Face status indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _detectedFaces.isNotEmpty
                            ? const Color(0xFF22C55E)
                            : Colors.white30,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _detectedFaces.isNotEmpty
                          ? 'Face detected — ready to capture'
                          : 'Looking for face...',
                      style: TextStyle(
                        color: _detectedFaces.isNotEmpty
                            ? const Color(0xFF22C55E)
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Capture button
                GestureDetector(
                  onTap: _isProcessing ? null : _captureAndProcessImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_themeColor, _themeDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _themeColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                            _isCheckIn
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: Colors.white,
                            size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _isCheckIn ? 'Capture & Check In' : 'Capture & Check Out',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
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
    );
  }

  Widget _buildFaceOverlay(Face face, double scale) {
    final rect = face.boundingBox;
    return Positioned(
      left: rect.left * scale,
      top: rect.top * scale,
      width: rect.width * scale,
      height: rect.height * scale,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF22C55E), width: 2.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.only(top: -20, left: 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Face Detected',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

// Custom painter for scan frame
class _ScanFramePainter extends CustomPainter {
  final Color color;
  final double progress;

  _ScanFramePainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const radius = 16.0;

    // Top-left
    canvas.drawLine(Offset(radius, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, radius), Offset(0, cornerLength), paint);
    canvas.drawArc(const Rect.fromLTWH(0, 0, radius * 2, radius * 2),
        pi, pi / 2, false, paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - cornerLength, 0), Offset(size.width - radius, 0), paint);
    canvas.drawLine(
        Offset(size.width, radius), Offset(size.width, cornerLength), paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2),
        -pi / 2,
        pi / 2,
        false,
        paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - cornerLength), Offset(0, size.height - radius), paint);
    canvas.drawLine(
        Offset(radius, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawArc(
        Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2),
        pi / 2,
        pi / 2,
        false,
        paint);

    // Bottom-right
    canvas.drawLine(
        Offset(size.width - cornerLength, size.height),
        Offset(size.width - radius, size.height),
        paint);
    canvas.drawLine(
        Offset(size.width, size.height - cornerLength),
        Offset(size.width, size.height - radius),
        paint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2,
            radius * 2, radius * 2),
        0,
        pi / 2,
        false,
        paint);

    // Scan line
    final scanPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final scanY = size.height * progress;
    canvas.drawLine(
        Offset(8, scanY), Offset(size.width - 8, scanY), scanPaint);
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => true;
}