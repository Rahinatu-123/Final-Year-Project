import 'package:flutter/material.dart';

class MeasurementProcessingScreen extends StatefulWidget {
  final String frontalPath;
  final String lateralPath;

  const MeasurementProcessingScreen({
    super.key,
    required this.frontalPath,
    required this.lateralPath,
  });

  @override
  State<MeasurementProcessingScreen> createState() =>
      _MeasurementProcessingScreenState();
}

class _MeasurementProcessingScreenState
    extends State<MeasurementProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup the Laser Scan Animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_scanController);

    // 2. Simulate the AI Processing time
    _startProcessing();
  }

  void _startProcessing() async {
    // This is where you would call your Firebase Upload and AI API
    await Future.delayed(const Duration(seconds: 6));

    if (mounted) {
      // Once done, move to the Results Screen
      Navigator.pushReplacementNamed(context, '/results');
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 60),
              const Text(
                "ANALYZING BODY PROPORTIONS",
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Display side-by-side photos
              Expanded(
                child: Row(
                  children: [
                    _buildImagePreview(widget.frontalPath, "FRONTAL"),
                    _buildImagePreview(widget.lateralPath, "LATERAL"),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Color(0xFFF06262)),
              const SizedBox(height: 20),
              const Text(
                "Extracting measurements...",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 60),
            ],
          ),

          // 3. THE LASER SCAN OVERLAY
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (context, child) {
              return Positioned(
                top:
                    150 +
                    (MediaQuery.of(context).size.height *
                        0.5 *
                        _scanAnimation.value),
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF06262),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF06262).withOpacity(0.8),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String path, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white24, size: 100),
                    // Use Image.file(File(path)) here in a real app
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
