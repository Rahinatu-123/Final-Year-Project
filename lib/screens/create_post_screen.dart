import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  List<File> _selectedMedia = [];
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  bool _isLoading = false;

  String _userName = 'Anonymous';
  String _userRole = 'Member';

  Set<String> _selectedTags = {'Traditional'};
  List<String> _availableTags = ['Traditional', 'Bridal', 'Casual', 'Lace'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (mounted) {
          setState(() {
            _userName = data?['fullName'] ?? data?['username'] ?? 'Anonymous';
            _userRole = data?['role'] ?? 'Member';
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load user data: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);

      if (pickedFiles.isEmpty) return;

      setState(() {
        _selectedMedia.addAll(pickedFiles.map((file) => File(file.path)));
      });
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (e.toString().contains('IMGMapper') ||
          e.toString().contains('metadata')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Image format not supported. Try a different image.',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick images'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      debugPrint('Video picked: ${pickedFile.path}');
      setState(() {
        _selectedMedia.add(File(pickedFile.path));
      });
    } catch (e) {
      debugPrint('Video picker error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to pick video'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
        ),
      );
    }
  }

  Future<void> _newUploadPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to post'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
      return;
    }

    if (_selectedMedia.isEmpty || _captionController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select media and write a caption'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> mediaUrls = [];
      String? videoUrl;
      String postType = 'image';

      for (final mediaFile in _selectedMedia) {
        final isVideo = _isVideoFile(mediaFile.path);
        if (isVideo) {
          postType = 'video';
          final uploadedVideoUrl = await _uploadVideoToCloudinary(
            mediaFile.path,
          );
          videoUrl = uploadedVideoUrl;
        } else {
          final uploadedImageUrl = await _uploadImageToCloudinary(
            mediaFile.path,
          );
          mediaUrls.add(uploadedImageUrl);
        }
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userType': _userRole.toLowerCase(),
        'userName': _userName,
        'userProfilePicUrl': '',
        'content': _captionController.text.trim(),
        'mediaUrls': mediaUrls,
        'videoUrl': videoUrl ?? '',
        'postType': postType,
        'likes': [],
        'likeCount': 0,
        'commentCount': 0,
        'shareCount': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'visibility': 'public',
        'tags': _selectedTags.toList(),
        'sharedStyleId': '',
        'sharedFabricId': '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post shared successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String> _uploadImageToCloudinary(String imagePath) async {
    const cloudName = 'dr8f7af8z';
    const uploadPreset = 'fashionHub_app';
    final imageFile = File(imagePath);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'fashionhub/posts'
      ..fields['quality'] = 'auto'
      ..fields['fetch_format'] = 'auto'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload image to Cloudinary');
    }

    final resStr = await response.stream.bytesToString();
    final resJson = json.decode(resStr);
    final secureUrl = resJson['secure_url'] as String;

    // Optimize URL with Cloudinary transformations for better loading
    // Format: https://res.cloudinary.com/cloud_name/image/upload/c_fill,w_800,h_600,q_auto,f_auto/image_id
    return _optimizeCloudinaryUrl(secureUrl);
  }

  String _optimizeCloudinaryUrl(String url) {
    try {
      // Convert standard Cloudinary URL to optimized URL with transformations
      // Example: https://res.cloudinary.com/dr8f7af8z/image/upload/v1234/fashionhub/posts/file_id
      // Becomes: https://res.cloudinary.com/dr8f7af8z/image/upload/c_fill,w_800,h_600,q_auto,f_auto,dpr_auto/v1234/fashionhub/posts/file_id
      if (!url.contains('res.cloudinary.com')) {
        return url;
      }

      // Insert transformations after /upload/
      final parts = url.split('/upload/');
      if (parts.length != 2) {
        return url;
      }

      // Add quality and format optimizations
      final transformations = 'c_fill,w_1000,h_800,q_auto,f_auto,dpr_auto';
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    } catch (e) {
      debugPrint('Error optimizing Cloudinary URL: $e');
      return url;
    }
  }

  Future<String> _uploadVideoToCloudinary(String videoPath) async {
    const cloudName = 'dr8f7af8z';
    const uploadPreset = 'fashionHub_app';
    final videoFile = File(videoPath);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'fashionhub/videos'
      ..fields['quality'] = 'auto'
      ..fields['fetch_format'] = 'auto'
      ..files.add(await http.MultipartFile.fromPath('file', videoFile.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload video to Cloudinary');
    }

    final resStr = await response.stream.bytesToString();
    final resJson = json.decode(resStr);
    return resJson['secure_url'];
  }

  bool _isVideoFile(String path) {
    final videoExtensions = [
      'mp4',
      'mov',
      'avi',
      'mkv',
      'flv',
      'wmv',
      'webm',
      '3gp',
      'ogv',
    ];
    final extension = path.toLowerCase().split('.').last;
    final isVideo = videoExtensions.contains(extension);
    debugPrint('File path: $path, Extension: $extension, Is Video: $isVideo');
    return isVideo;
  }

  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: const Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
        title: Text('Create Post', style: AppTextStyles.h4),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            GestureDetector(
              onTap: _newUploadPost,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.warmGradient,
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Share',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Uploading your design...",
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: AppColors.warmGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.surfaceVariant,
                          child: Icon(
                            Icons.person,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.xs,
                              ),
                            ),
                            child: Text(
                              _userRole,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Media picker section
                  if (_selectedMedia.isEmpty)
                    GestureDetector(
                      onTap: () => _showMediaPickerOptions(),
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.lg,
                          ),
                          border: Border.all(
                            color: AppColors.textTertiary.withOpacity(0.3),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to add photos or videos',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Share your latest design or inspiration',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Selected Media (${_selectedMedia.length})",
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._selectedMedia.asMap().entries.map((entry) {
                                int idx = entry.key;
                                File file = entry.value;
                                bool isVideo = _isVideoFile(file.path);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppBorderRadius.md,
                                        ),
                                        child: isVideo
                                            ? Container(
                                                width: 120,
                                                height: 120,
                                                color: AppColors.surface,
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.videocam,
                                                      size: 40,
                                                      color: AppColors.primary,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Video',
                                                      style: AppTextStyles
                                                          .labelSmall,
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Image.file(
                                                file,
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedMedia.removeAt(idx);
                                          }),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppColors.textPrimary
                                                  .withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              GestureDetector(
                                onTap: () => _showMediaPickerOptions(),
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.md,
                                    ),
                                    border: Border.all(
                                      color: AppColors.primary.withOpacity(0.5),
                                      width: 2,
                                      strokeAlign: BorderSide.strokeAlignInside,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _selectedMedia.map((file) {
                            bool isVideo = _isVideoFile(file.path);
                            int index = _selectedMedia.indexOf(file);

                            return Chip(
                              avatar: Icon(
                                isVideo ? Icons.videocam : Icons.image,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: Text(
                                isVideo
                                    ? 'Video ${index + 1}'
                                    : 'Image ${index + 1}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppColors.primary,
                              deleteIcon: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                              onDeleted: () => setState(() {
                                _selectedMedia.remove(file);
                              }),
                            );
                          }).toList(),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Caption label
                  Text(
                    "Caption",
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Caption input
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      boxShadow: AppShadows.soft,
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: 5,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText:
                            'Write a caption for your design or fabric...',
                        hintStyle: AppTextStyles.bodyMedium,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags section
                  Text(
                    "Add Tags",
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ..._availableTags
                          .map((tag) => _buildTagChip(tag))
                          .toList(),
                      _buildTagChip("+ Add", isAdd: true),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTagChip(String label, {bool isAdd = false}) {
    bool isSelected = _selectedTags.contains(label);

    return GestureDetector(
      onTap: () {
        if (isAdd) {
          _showAddTagDialog();
        } else {
          setState(() {
            if (isSelected) {
              _selectedTags.remove(label);
            } else {
              _selectedTags.add(label);
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.warmGradient : null,
          color: isSelected
              ? null
              : isAdd
              ? AppColors.surfaceVariant
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.xl),
          border: isSelected || isAdd
              ? null
              : Border.all(color: AppColors.textTertiary.withOpacity(0.3)),
          boxShadow: isSelected ? AppShadows.colored(AppColors.coral) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdd) Icon(Icons.add, size: 16, color: AppColors.primary),
            if (isAdd) const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : isAdd
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    _tagController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Add Custom Tag',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: _tagController,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Enter tag name',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.textTertiary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.textTertiary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final tagName = _tagController.text.trim();
              if (tagName.isNotEmpty && !_availableTags.contains(tagName)) {
                setState(() {
                  _availableTags.add(tagName);
                  _selectedTags.add(tagName);
                });
                Navigator.pop(context);
              } else if (_availableTags.contains(tagName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Tag already exists'),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Add',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      backgroundColor: AppColors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Media',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.collections_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Images',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Add multiple photos',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  border: Border.all(color: AppColors.coral.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.videocam_outlined,
                      color: AppColors.coral,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Video',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Add a video to your post',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
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
