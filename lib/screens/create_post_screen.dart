import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  File? _image;
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

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
      });
    } catch (e) {
      debugPrint('Image picker error: $e');
      if (e.toString().contains('IMGMapper') ||
          e.toString().contains('metadata')) {
        // This is a metadata-related error, show user-friendly message
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
            content: const Text('Failed to pick image'),
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

  Future<void> _uploadPost() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
      return;
    }

    if (_image == null || _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select an image and write a caption'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fileName =
          'posts/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(_image!);

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image uploaded successfully: $imageUrl');

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'userType': _userRole.toLowerCase(),
        'userName': _userName,
        'userProfilePicUrl': '',
        'content': _captionController.text.trim(),
        'mediaUrls': [imageUrl],
        'videoUrl': '',
        'postType': 'image',
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

      debugPrint('Post created successfully with mediaUrls: [${imageUrl}]');

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
      debugPrint('Post upload failed: $e');
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              onTap: _uploadPost,
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

                  // Image picker box
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 320,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                        border: Border.all(
                          color: _image != null
                              ? Colors.transparent
                              : AppColors.textTertiary.withOpacity(0.3),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        boxShadow: AppShadows.soft,
                      ),
                      child: _image != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppBorderRadius.lg,
                                  ),
                                  child: Image.file(
                                    _image!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _image = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.textPrimary
                                            .withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
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
                                  'Tap to add a photo',
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
}
