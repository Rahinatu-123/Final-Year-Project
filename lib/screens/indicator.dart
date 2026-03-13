import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'photo_capture_screen.dart';

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
  bool _isMale = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Randomly select between male and female body images
    _isMale = Random().nextBool();
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
        child: Stack(
          children: [
            PageView(
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
            // Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
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
            "Stand facing the camera like this",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 30),
          // Frontal body position image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Image.asset(
                _isMale
                    ? 'assets/front.png'
                    : 'assets/body_position_frontal.jpg',
                fit: BoxFit.contain,
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
          // Lateral body position image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Image.asset(
                _isMale
                    ? 'assets/side.png'
                    : 'assets/body_position_lateral.png',
                fit: BoxFit.contain,
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
                        builder: (context) => const PhotoCaptureScreen(),
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
