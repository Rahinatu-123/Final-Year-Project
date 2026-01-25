import 'package:flutter/material.dart';

class MeasurementResultWidget extends StatelessWidget {
  final String imagePath;
  final Map<String, double> measurements;

  const MeasurementResultWidget({
    super.key,
    required this.imagePath,
    required this.measurements,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // THE INTERACTIVE IMAGE
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.black12,
          ),
          child: Stack(
            children: [
              // 1. The Captured Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Center(
                  child: Icon(Icons.person, size: 300, color: Colors.grey[400]),
                  // Replace with Image.file(File(imagePath))
                ),
              ),

              // 2. The Measurement Labels (Call-outs)
              _buildLabel(
                top: 150,
                left: 40,
                label: "BUST",
                value: "${measurements['bust']}\"",
              ),
              _buildLabel(
                top: 220,
                right: 40,
                label: "WAIST",
                value: "${measurements['waist']}\"",
              ),
              _buildLabel(
                top: 290,
                left: 40,
                label: "HIPS",
                value: "${measurements['hips']}\"",
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // 3. THE SHARING BUTTONS
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                icon: Icons.share,
                label: "Share as Image",
                color: Colors.black,
                onTap: () => _shareAsImage(),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildShareButton(
                icon: Icons.send_rounded,
                label: "Send to Tailor",
                color: const Color(0xFFF06262),
                onTap: () => _sendToTailor(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel({
    double? top,
    double? left,
    double? right,
    required String label,
    required String value,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Column(
        crossAxisAlignment: left != null
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF06262),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _shareAsImage() {
    // Logic to use 'screenshot' package to capture the widget and share
  }

  void _sendToTailor() {
    // Logic to open a contact picker or search for a professional in the app
  }
}
