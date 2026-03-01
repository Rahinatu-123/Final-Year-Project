import 'package:flutter/material.dart';
import 'dart:async';
import 'overlay.dart';

class MeasurementIndicationScreen extends StatefulWidget {
  const MeasurementIndicationScreen({super.key});

  @override
  State<MeasurementIndicationScreen> createState() =>
      _MeasurementIndicationScreenState();
}

class _MeasurementIndicationScreenState
    extends State<MeasurementIndicationScreen> {
  late PageController _pageController;
  Timer? _autoAdvanceTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 10), () {
      if (_currentPage == 1 && _pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
              if (page == 1) {
                _startAutoAdvance();
              } else {
                _autoAdvanceTimer?.cancel();
              }
            });
          },
          children: [
            // Page 1: Instructions
            _buildInstructionsPage(context),
            // Page 2: Frontal View
            _buildFrontalViewPage(context),
            // Page 3: Lateral View
            _buildLateralViewPage(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.accessibility_new_rounded,
            color: Color(0xFFF06262),
            size: 80,
          ),
          const SizedBox(height: 20),
          const Text(
            "AI Body Scan",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "For the most accurate custom fit, follow these steps precisely.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),
          // Steps List
          _buildStep(
            Icons.checkroom,
            "Wear form-fitting clothes (e.g., leggings/t-shirt).",
          ),
          _buildStep(Icons.wb_sunny_outlined, "Ensure the room is well-lit."),
          _buildStep(
            Icons.person_pin_circle_outlined,
            "Stand 2 meters away from the camera.",
          ),
          _buildStep(
            Icons.phonelink_ring_outlined,
            "Keep the phone perfectly vertical.",
          ),
          const Spacer(),
          // Next Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF06262),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                "NEXT",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "Page ${_currentPage + 1} of 3",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFrontalViewPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "Frontal View",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Stand facing the camera like this\n(Auto-advancing in 10 seconds...)",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
          // Frontal body position visualization
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: CustomPaint(
                painter: FrontalBodyPositionPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "Page ${_currentPage + 1} of 3",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLateralViewPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const SizedBox(height: 30),
          const Text(
            "Lateral View",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Stand sideways to the camera like this",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
          // Lateral body position visualization
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: CustomPaint(
                painter: LateralBodyPositionPainter(),
                size: Size.infinite,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFF06262)),
                  ),
                  child: const Text(
                    "BACK",
                    style: TextStyle(
                      color: Color(0xFFF06262),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AICameraOverlay(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF06262),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "I'M READY",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Page ${_currentPage + 1} of 3",
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStep(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

// Frontal body position painter
class FrontalBodyPositionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF8B6F47)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFA0826D)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final topY = size.height * 0.1;

    // Head
    canvas.drawCircle(Offset(centerX, topY + 40), 30, fillPaint);
    canvas.drawCircle(Offset(centerX, topY + 40), 30, strokePaint);

    // Neck
    canvas.drawLine(
      Offset(centerX, topY + 70),
      Offset(centerX, topY + 90),
      strokePaint,
    );

    // Torso (wider for realistic body)
    final torsoPath = Path();
    torsoPath.moveTo(centerX - 35, topY + 90);
    torsoPath.lineTo(centerX - 40, topY + 160);
    torsoPath.lineTo(centerX + 40, topY + 160);
    torsoPath.lineTo(centerX + 35, topY + 90);
    torsoPath.close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, strokePaint);

    // Left arm
    canvas.drawLine(
      Offset(centerX - 35, topY + 100),
      Offset(centerX - 75, topY + 140),
      strokePaint..strokeWidth = 8,
    );

    // Right arm
    canvas.drawLine(
      Offset(centerX + 35, topY + 100),
      Offset(centerX + 75, topY + 140),
      strokePaint..strokeWidth = 8,
    );

    // Left leg
    canvas.drawLine(
      Offset(centerX - 20, topY + 160),
      Offset(centerX - 20, size.height * 0.85),
      strokePaint..strokeWidth = 8,
    );

    // Right leg
    canvas.drawLine(
      Offset(centerX + 20, topY + 160),
      Offset(centerX + 20, size.height * 0.85),
      strokePaint..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(FrontalBodyPositionPainter oldDelegate) => false;
}

// Lateral body position painter
class LateralBodyPositionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = const Color(0xFF8B6F47)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFA0826D)
      ..style = PaintingStyle.fill;

    final startX = size.width * 0.3;
    final topY = size.height * 0.1;

    // Head (profile)
    canvas.drawCircle(Offset(startX + 40, topY + 40), 30, fillPaint);
    canvas.drawCircle(Offset(startX + 40, topY + 40), 30, strokePaint);

    // Neck
    canvas.drawLine(
      Offset(startX + 40, topY + 70),
      Offset(startX + 40, topY + 90),
      strokePaint,
    );

    // Torso (angled for lateral view)
    final torsoPath = Path();
    torsoPath.moveTo(startX + 40, topY + 90);
    torsoPath.lineTo(startX + 35, topY + 100);
    torsoPath.lineTo(startX + 30, topY + 160);
    torsoPath.lineTo(startX + 50, topY + 160);
    torsoPath.lineTo(startX + 45, topY + 100);
    torsoPath.close();
    canvas.drawPath(torsoPath, fillPaint);
    canvas.drawPath(torsoPath, strokePaint);

    // Front arm (raised)
    canvas.drawLine(
      Offset(startX + 40, topY + 105),
      Offset(startX + 85, topY + 80),
      strokePaint..strokeWidth = 8,
    );

    // Back arm (relaxed)
    canvas.drawLine(
      Offset(startX + 40, topY + 110),
      Offset(startX - 5, topY + 125),
      strokePaint..strokeWidth = 8,
    );

    // Front leg
    canvas.drawLine(
      Offset(startX + 40, topY + 160),
      Offset(startX + 40, size.height * 0.85),
      strokePaint..strokeWidth = 8,
    );

    // Back leg
    canvas.drawLine(
      Offset(startX + 40, topY + 160),
      Offset(startX + 10, size.height * 0.85),
      strokePaint..strokeWidth = 8,
    );
  }

  @override
  bool shouldRepaint(LateralBodyPositionPainter oldDelegate) => false;
}
