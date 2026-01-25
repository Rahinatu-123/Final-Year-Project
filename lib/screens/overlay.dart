import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class AICameraOverlay extends StatefulWidget {
  const AICameraOverlay({super.key});

  @override
  State<AICameraOverlay> createState() => _AICameraOverlayState();
}

class _AICameraOverlayState extends State<AICameraOverlay> {
  CameraController? _controller;
  bool _isFrontal = true; // Toggle between Front and Side view
  List<CameraDescription>? _cameras;

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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();
      // Handle the image (save locally or send to processing)
      if (_isFrontal) {
        setState(() => _isFrontal = false); // Move to side view
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Frontal saved! Now stand sideways.")),
        );
      } else {
        // Both photos taken - navigate to processing
        Navigator.pushReplacementNamed(context, '/processing');
      }
    } catch (e) {
      print(e);
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

          // 3. UI CONTROLS
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
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
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
