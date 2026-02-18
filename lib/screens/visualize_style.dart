import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fashionhub/screens/style_gallery.dart';
import '../theme/app_theme.dart';

// =====================================================
// VISUALIZE STYLE PAGE
// =====================================================

class VisualizeStylePage extends StatefulWidget {
  const VisualizeStylePage({super.key});

  @override
  State<VisualizeStylePage> createState() => _VisualizeStylePageState();
}

class _VisualizeStylePageState extends State<VisualizeStylePage> {
  File? _selectedImage;
  bool _isImageSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Visualize Style",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text("Get Started", style: AppTextStyles.h2),
              const SizedBox(height: 8),
              Text(
                "Choose an image to visualize with different styles",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Image Preview Area
              Expanded(
                child: Column(
                  children: [
                    // Image Display
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: _isImageSelected
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.lg,
                              ),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  size: 64,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No image selected",
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Choose or take a photo to continue",
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    if (!_isImageSelected) ...[
                      // Image Selection Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              "Upload Image",
                              Icons.upload_file,
                              AppColors.primary,
                              () => _pickImage(ImageSource.gallery),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              "Take Photo",
                              Icons.camera_alt,
                              AppColors.secondary,
                              () => _pickImage(ImageSource.camera),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Style Selection Buttons
                      Text("Choose how to proceed:", style: AppTextStyles.h4),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              "Upload Style",
                              Icons.style,
                              AppColors.coral,
                              () => _showUploadStyleDialog(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              "Select Style",
                              Icons.style_outlined,
                              AppColors.gold,
                              () => _navigateToStyleGallery(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Reset Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _resetImage,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Choose Different Image"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.textTertiary),
                            foregroundColor: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isImageSelected = true;
      });
    }
  }

  void _resetImage() {
    setState(() {
      _selectedImage = null;
      _isImageSelected = false;
    });
  }

  void _showUploadStyleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Upload Style"),
        content: const Text(
          "Style upload feature coming soon! For now, please select a style from our gallery.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToStyleGallery();
            },
            child: const Text("Go to Gallery"),
          ),
        ],
      ),
    );
  }

  void _navigateToStyleGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const StyleGalleryPage(title: null, categories: []),
      ),
    );
  }
}
