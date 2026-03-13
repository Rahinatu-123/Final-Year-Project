import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/tryon_service.dart';

class TryOnScreen extends StatefulWidget {
  final String? personImagePath;
  final String? garmentImagePath;

  const TryOnScreen({super.key, this.personImagePath, this.garmentImagePath});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _personImagePath;
  String? _garmentImagePath;
  Uint8List? _resultImageBytes;
  bool _isLoading = false;
  String _category = 'Upper-body';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-populate person image if passed from visualize_style

    if (widget.personImagePath != null) {
      _personImagePath = widget.personImagePath;

      // Verify file exists
      final file = File(_personImagePath!);

      if (!file.existsSync()) {
        // File does not exist at path
      }
    }

    // Pre-populate garment image if passed from style detail or gallery
    if (widget.garmentImagePath != null) {
      _garmentImagePath = widget.garmentImagePath;

      final isUrl =
          _garmentImagePath!.startsWith('http://') ||
          _garmentImagePath!.startsWith('https://');

      if (isUrl) {
        // Garment is a URL
      } else {
        final file = File(_garmentImagePath!);
        if (!file.existsSync()) {
          // Garment file exists check
        }
      }
    }
  }

  // Let user pick a photo from camera or gallery
  Future<void> _pickImage(bool isPerson) async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file != null) {
      setState(() {
        if (isPerson) {
          _personImagePath = file.path;
        } else {
          _garmentImagePath = file.path;
        }
        _resultImageBytes = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _runTryOn() async {
    if (_personImagePath == null || _garmentImagePath == null) {
      setState(
        () =>
            _errorMessage = 'Please select both a person and a garment image.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultImageBytes = null;
    });

    try {
      final bytes = await TryOnService.tryOn(
        personImagePath: _personImagePath!,
        garmentImagePath: _garmentImagePath!,
        category: _category,
      );
      setState(() => _resultImageBytes = bytes);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('African Style Try-On')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category selector
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Garment category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Upper-body',
                  child: Text('Upper body (tops, shirts)'),
                ),
                DropdownMenuItem(
                  value: 'Lower-body',
                  child: Text('Lower body (skirts, trousers)'),
                ),
                DropdownMenuItem(value: 'Dresses', child: Text('Dresses')),
              ],
              onChanged: (val) => setState(() => _category = val!),
            ),

            const SizedBox(height: 16),

            // Image pickers side by side
            Row(
              children: [
                Expanded(
                  child: _ImagePickerCard(
                    label: 'Person',
                    imagePath: _personImagePath,
                    onTap: () => _pickImage(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImagePickerCard(
                    label: 'Garment',
                    imagePath: _garmentImagePath,
                    onTap: () => _pickImage(false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Try-on button
            ElevatedButton(
              onPressed: _isLoading ? null : _runTryOn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Processing (30-60 seconds)...'),
                      ],
                    )
                  : const Text('Try On', style: TextStyle(fontSize: 16)),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],

            // Result image
            if (_resultImageBytes != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Result',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_resultImageBytes!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Simple image picker card widget
class _ImagePickerCard extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTap;

  const _ImagePickerCard({
    required this.label,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Colors.grey)),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _buildImage(imagePath!),
              ),
      ),
    );
  }

  // Helper method to determine if path is URL or local file and display accordingly
  Widget _buildImage(String imagePath) {
    final isUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    if (isUrl) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Error loading image',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Error loading image',
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      );
    }
  }
}
