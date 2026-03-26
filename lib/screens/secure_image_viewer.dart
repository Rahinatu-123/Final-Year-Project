import 'package:flutter/material.dart';

import '../services/secure_screen_service.dart';
import '../theme/app_theme.dart';

class SecureImageViewer extends StatefulWidget {
  final String imageUrl;
  final String watermarkText;
  final bool isExpired;

  const SecureImageViewer({
    super.key,
    required this.imageUrl,
    required this.watermarkText,
    required this.isExpired,
  });

  @override
  State<SecureImageViewer> createState() => _SecureImageViewerState();
}

class _SecureImageViewerState extends State<SecureImageViewer> {
  @override
  void initState() {
    super.initState();
    SecureScreenService.setSecureScreen(true);
  }

  @override
  void dispose() {
    SecureScreenService.setSecureScreen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Secure Image'),
      ),
      body: widget.isExpired
          ? const Center(
              child: Text(
                'This image has expired.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Text(
                          'Unable to load image',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: SecureWatermarkOverlay(text: widget.watermarkText),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: const Text(
                      'For tailoring support only. Screenshot and download are restricted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class SecureWatermarkOverlay extends StatelessWidget {
  final String text;

  const SecureWatermarkOverlay({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final items = <Widget>[];
        for (double y = 40; y < constraints.maxHeight; y += 120) {
          for (double x = 16; x < constraints.maxWidth; x += 180) {
            items.add(
              Positioned(
                left: x,
                top: y,
                child: Transform.rotate(
                  angle: -0.35,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.22),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }
        }
        return Stack(children: items);
      },
    );
  }
}
