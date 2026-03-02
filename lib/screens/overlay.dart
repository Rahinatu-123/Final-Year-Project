import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';

class AICameraOverlay extends StatefulWidget {
  const AICameraOverlay({super.key});

  @override
  State<AICameraOverlay> createState() => _AICameraOverlayState();
}

class _AICameraOverlayState extends State<AICameraOverlay> {
  CameraController? _controller;
  bool _isFrontal = true;
  List<CameraDescription>? _cameras;
  bool _isAligned = false;
  bool _isProcessing = false;
  Timer? _alignmentTimer;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras![0], ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  void _startAlignment() {
    // Simulate alignment detection - user has 5 seconds to stay still
    if (!_isAligned && !_isProcessing) {
      setState(() => _isAligned = true);
      _alignmentTimer?.cancel();
      _alignmentTimer = Timer(const Duration(seconds: 5), () {
        if (_isAligned && mounted && !_isProcessing) {
          _takePicture();
        }
      });
    }
  }

  void _cancelAlignment() {
    _alignmentTimer?.cancel();
    setState(() => _isAligned = false);
  }

  @override
  void dispose() {
    _alignmentTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() => _isProcessing = true);
      final image = await _controller!.takePicture();

      if (_isFrontal) {
        setState(() {
          _isFrontal = false;
          _isAligned = false;
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Frontal saved! Now stand sideways.")),
        );
      } else {
        // Both photos taken - navigate to processing
        Navigator.pushReplacementNamed(context, '/processing');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isAligned = false;
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. LIVE CAMERA FEED
          SizedBox.expand(child: CameraPreview(_controller!)),

          // 2. THE SILHOUETTE OVERLAY
          Center(
            child: Opacity(
              opacity: 0.5,
              child: Icon(
                _isFrontal ? Icons.accessibility_new : Icons.directions_walk,
                size: MediaQuery.of(context).size.height * 0.7,
                color: Colors.white,
              ),
            ),
          ),

          // 3. ALIGNMENT GUIDES
          if (_isAligned)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(painter: AlignmentGuidePainter()),
            ),

          // 4. UI CONTROLS
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isFrontal ? "ALIGN FRONTAL POSE" : "ALIGN LATERAL POSE",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 18,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                  ),
                ),
                const SizedBox(height: 10),
                // Alignment indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _isAligned ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isAligned ? Icons.check_circle : Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isAligned
                            ? "Hold still... Capturing in 5s"
                            : "Tap button and hold still",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Camera button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isAligned)
                      GestureDetector(
                        onTap: _cancelAlignment,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stop,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _startAlignment,
                        onLongPress: _startAlignment,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isProcessing
                                ? Icons.hourglass_empty
                                : Icons.camera_alt,
                            size: 40,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // BACK BUTTON
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class AlignmentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Draw rectangle guide
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: size.width * 0.6,
        height: size.height * 0.8,
      ),
      paint,
    );

    // Draw corner circles
    final cornerPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    const cornerRadius = 15.0;
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: size.width * 0.6,
      height: size.height * 0.8,
    );

    // Top left
    canvas.drawCircle(rect.topLeft, cornerRadius, cornerPaint);
    // Top right
    canvas.drawCircle(rect.topRight, cornerRadius, cornerPaint);
    // Bottom left
    canvas.drawCircle(rect.bottomLeft, cornerRadius, cornerPaint);
    // Bottom right
    canvas.drawCircle(rect.bottomRight, cornerRadius, cornerPaint);
  }

  @override
  bool shouldRepaint(AlignmentGuidePainter oldDelegate) => false;
}
