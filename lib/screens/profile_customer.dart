import 'dart:io';
import 'package:fashionhub/screens/business_profile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import 'landing_page.dart';
import 'create_post_screen.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late Map<String, int> _carouselIndices = {};

  String _displayName = "Loading...";
  String? _photoUrl;
  String _userRole = "Member";
  bool _isLoading = true;
  bool _isSaving = false;
  bool _showAccountSettings = false;

  // Business profile data for tailors/seamstresses
  String? _businessName;
  String? _businessAddress;
  String? _businessPhone;
  String? _businessEmail;
  double? _businessLatitude;
  double? _businessLongitude;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _usernameController.text =
                data['username'] ?? data['fullName'] ?? "";
            _descriptionController.text = data['description'] ?? "";
            _displayName = data['username'] ?? data['fullName'] ?? "User";
            _userRole = data['role'] ?? "Member";

            // Load business profile data for tailors/seamstresses
            if (_userRole.toLowerCase().contains('tailor') ||
                _userRole.toLowerCase().contains('seamstress')) {
              _businessName = data['businessName'];
              _businessAddress = data['businessAddress'];
              _businessPhone = data['businessPhone'];
              _businessEmail = data['businessEmail'];
              _businessLatitude = data['businessLatitude']?.toDouble();
              _businessLongitude = data['businessLongitude']?.toDouble();
            }

            // Try to get profile picture from Cloudinary first, then fall back to Auth
            _photoUrl = data['profilePictureUrl'] ?? user.photoURL;
            _isLoading = false;
          });
        } else {
          setState(() {
            _displayName = user.displayName ?? "New User";
            _photoUrl = user.photoURL;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint("Error loading profile: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'username': _usernameController.text,
          'description': _descriptionController.text,
          'lastUpdated': Timestamp.now(),
        }, SetOptions(merge: true));

        // Reload user data to reflect changes immediately
        await _loadUserData();

        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Profile Updated Successfully!"),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        debugPrint("Error saving: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
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
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Upload to Cloudinary
      try {
        setState(() => _isSaving = true);
        final uploadedUrl = await _uploadProfilePictureToCloudinary(image.path);

        // Save the Cloudinary URL to Firebase
        final User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'profilePictureUrl': uploadedUrl,
                'lastUpdated': Timestamp.now(),
              }, SetOptions(merge: true));

          if (mounted) {
            setState(() {
              _photoUrl = uploadedUrl;
              _isSaving = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Profile picture updated successfully!"),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error uploading picture: $e"),
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
  }

  Future<String> _uploadProfilePictureToCloudinary(String imagePath) async {
    const cloudName = 'dr8f7af8z';
    const uploadPreset = 'fashionHub_app';
    final imageFile = File(imagePath);
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'fashionhub/profile'
      ..fields['quality'] = 'auto'
      ..fields['fetch_format'] = 'auto'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to upload profile picture to Cloudinary');
    }

    final resStr = await response.stream.bytesToString();
    final resJson = json.decode(resStr);
    final secureUrl = resJson['secure_url'] as String;

    // Optimize URL for profile pictures
    return _optimizeProfilePictureUrl(secureUrl);
  }

  String _optimizeProfilePictureUrl(String url) {
    try {
      if (!url.contains('res.cloudinary.com')) {
        return url;
      }

      final parts = url.split('/upload/');
      if (parts.length != 2) {
        return url;
      }

      // Transformations for profile pictures: circular crop, smaller size
      final transformations = 'c_fill,w_300,h_300,q_auto,f_auto,dpr_auto';
      return '${parts[0]}/upload/$transformations/${parts[1]}';
    } catch (e) {
      debugPrint('Error optimizing profile picture URL: $e');
      return url;
    }
  }

  Future<void> _changePassword(String currentPass, String newPass) async {
    final user = FirebaseAuth.instance.currentUser;
    final cred = EmailAuthProvider.credential(
      email: user!.email!,
      password: currentPass,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Password Updated Successfully"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${e.toString()}"),
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

  void _showPasswordModal() {
    final TextEditingController currentPass = TextEditingController();
    final TextEditingController newPass = TextEditingController();
    final TextEditingController confirmPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text("Change Password", style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              "Enter your current password and create a new one",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            _buildModalField(currentPass, "Current Password"),
            _buildModalField(newPass, "New Password"),
            _buildModalField(confirmPass, "Confirm New Password"),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                boxShadow: AppShadows.colored(AppColors.coral),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
                onPressed: () {
                  if (newPass.text == confirmPass.text &&
                      newPass.text.length >= 6) {
                    _changePassword(currentPass.text, newPass.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          "Passwords must match and be 6+ chars",
                        ),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  "Update Password",
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content section based on user role
                        Text(
                          _userRole.toLowerCase().contains('tailor') ||
                                  _userRole.toLowerCase().contains('seamstress')
                              ? "Business Portfolio"
                              : "My Posts",
                          style: AppTextStyles.h4,
                        ),
                        const SizedBox(height: 16),

                        // Show different content based on role
                        if (_userRole.toLowerCase().contains('tailor') ||
                            _userRole.toLowerCase().contains('seamstress'))
                          _buildBusinessPortfolioSection()
                        else
                          _buildMyPostsSection(),

                        const SizedBox(height: 28),

                        // Account Settings (Collapsible)
                        GestureDetector(
                          onTap: () => setState(
                            () => _showAccountSettings = !_showAccountSettings,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.md,
                              ),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Account Settings",
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(
                                  _showAccountSettings
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Account Settings Content
                        if (_showAccountSettings) ...[
                          const SizedBox(height: 12),
                          _buildSettingsTile(
                            Icons.person_outline,
                            "Username",
                            _usernameController.text.isEmpty
                                ? "Set your username"
                                : _usernameController.text,
                            onTap: () => _showEditUsernameDialog(),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingsTile(
                            Icons.lock_outline,
                            "Password",
                            "••••••••",
                            onTap: _showPasswordModal,
                          ),
                          const SizedBox(height: 12),
                          _buildSettingsTile(
                            Icons.notifications_outlined,
                            "Notifications",
                            "Manage your preferences",
                            onTap: () {},
                          ),
                        ],

                        const SizedBox(height: 20),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "My Profile",
                    style: AppTextStyles.h4.copyWith(color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: GestureDetector(
                      onTap: _showEditProfileDialog,
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile section with picture and info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.medium,
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: _photoUrl != null
                              ? (_photoUrl!.startsWith('http')
                                    ? NetworkImage(_photoUrl!)
                                    : FileImage(File(_photoUrl!))
                                          as ImageProvider)
                              : null,
                          child: _photoUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.textTertiary,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // User info and stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          _displayName,
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.xl,
                            ),
                          ),
                          child: Text(
                            _userRole,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats row (Posts, Followers, Following)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            // Posts count
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseAuth.instance.currentUser != null
                                  ? FirebaseFirestore.instance
                                        .collection('posts')
                                        .where(
                                          'userId',
                                          isEqualTo: FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .snapshots()
                                  : const Stream.empty(),
                              builder: (context, snap) {
                                final postCount = snap.hasData
                                    ? snap.data!.docs.length
                                    : 0;
                                return _buildHeaderStatItem(
                                  postCount.toString(),
                                  "Posts",
                                );
                              },
                            ),
                            const SizedBox(width: 20),

                            // Followers & Following counts from user doc
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseAuth.instance.currentUser != null
                                  ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                        )
                                        .snapshots()
                                  : const Stream.empty(),
                              builder: (context, userSnap) {
                                int followers = 0;
                                int following = 0;
                                if (userSnap.hasData && userSnap.data != null) {
                                  final data =
                                      userSnap.data!.data()
                                          as Map<String, dynamic>?;
                                  if (data != null) {
                                    followers = (data['followersCount'] is int)
                                        ? data['followersCount'] as int
                                        : (data['followers'] is List)
                                        ? (data['followers'] as List).length
                                        : 0;
                                    following = (data['followingCount'] is int)
                                        ? data['followingCount'] as int
                                        : (data['following'] is List)
                                        ? (data['following'] as List).length
                                        : 0;
                                  }
                                }

                                return Row(
                                  children: [
                                    _buildHeaderStatItem(
                                      followers.toString(),
                                      'Followers',
                                    ),
                                    const SizedBox(width: 20),
                                    _buildHeaderStatItem(
                                      following.toString(),
                                      'Following',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Business Information Section (for tailors/seamstresses)
              if ((_userRole.toLowerCase().contains('tailor') ||
                      _userRole.toLowerCase().contains('seamstress')) &&
                  (_businessName != null || _businessAddress != null))
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.business,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Business Information',
                                style: AppTextStyles.h4.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Business Details',
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Business Name
                      if (_businessName != null &&
                          _businessName!.isNotEmpty) ...[
                        Text(
                          'Business Name',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _businessName!,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Business Address
                      if (_businessAddress != null &&
                          _businessAddress!.isNotEmpty) ...[
                        Text(
                          'Address',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_businessAddress!, style: AppTextStyles.bodyLarge),
                        const SizedBox(height: 12),
                      ],

                      // Business Contact Info
                      if ((_businessPhone != null &&
                              _businessPhone!.isNotEmpty) ||
                          (_businessEmail != null &&
                              _businessEmail!.isNotEmpty)) ...[
                        Text(
                          'Contact',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_businessPhone != null &&
                            _businessPhone!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _businessPhone!,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        if (_businessEmail != null &&
                            _businessEmail!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.email,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _businessEmail!,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],

                      // Location Map (if coordinates available)
                      if (_businessLatitude != null &&
                          _businessLongitude != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                            border: Border.all(
                              color: AppColors.textTertiary.withOpacity(0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                            child: Stack(
                              children: [
                                // Simple map placeholder
                                Container(
                                  color: AppColors.surfaceVariant,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 48,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Business Location',
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Lat: ${_businessLatitude!.toStringAsFixed(4)}, Lng: ${_businessLongitude!.toStringAsFixed(4)}',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.sm,
                                      ),
                                    ),
                                    child: Text(
                                      'MAP VIEW',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Bio section
              if (_descriptionController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _descriptionController.text,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [_buildStatItem("0", "Posts")],
      ),
    );
  }

  Widget _buildMyPostsSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Text(
          'Please log in to view your posts',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('Error loading posts: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Error loading posts',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 48,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No posts yet',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        // Collect docs and sort them by timestamp (descending) client-side
        final posts = snapshot.data!.docs.map((doc) => doc).toList()
          ..sort((a, b) {
            final aTs =
                (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTs =
                (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final aMillis = aTs?.millisecondsSinceEpoch ?? 0;
            final bMillis = bTs?.millisecondsSinceEpoch ?? 0;
            return bMillis.compareTo(aMillis); // newest first
          });

        return Column(
          children: [...posts.map((post) => _buildPostItem(post)).toList()],
        );
      },
    );
  }

  Widget _buildPostItem(DocumentSnapshot post) {
    final data = post.data() as Map<String, dynamic>;
    final mediaUrls = data['mediaUrls'] as List<dynamic>? ?? [];
    final videoUrl = data['videoUrl'] as String?;
    final content = data['content'] as String? ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final postType = data['postType'] as String? ?? 'image';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media preview
          if (postType == 'video' && videoUrl != null && videoUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppBorderRadius.lg),
                  topRight: Radius.circular(AppBorderRadius.lg),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.videocam, size: 50, color: AppColors.primary),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(
                        'VIDEO',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (mediaUrls.isNotEmpty)
            _buildProfileImageCarousel(post.id, mediaUrls),

          // Post content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caption
                if (content.isNotEmpty)
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium,
                  ),

                if (content.isNotEmpty) const SizedBox(height: 12),

                // Post info row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          timestamp != null
                              ? _formatDate(timestamp.toDate())
                              : 'Unknown date',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.favorite_outline,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data['likeCount'] ?? 0}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(post.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text(
          'Delete Post',
          style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _deletePost(postId);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageCarousel(String postId, List<dynamic> mediaUrls) {
    final imageUrls = mediaUrls.cast<String>();

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 150,
          child: PageView.builder(
            onPageChanged: (index) {
              setState(() {
                _carouselIndices[postId] = index;
              });
            },
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Image counter badge (only show if multiple images)
        if (imageUrls.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Text(
                '${(_carouselIndices[postId] ?? 0) + 1}/${imageUrls.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to delete post'),
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

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelMedium),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.textPrimary.withOpacity(0.1),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: _descriptionController,
        maxLines: 4,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: "Describe your fashion style...",
          hintStyle: AppTextStyles.bodyMedium,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildModalField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: TextField(
          controller: controller,
          obscureText: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyles.labelMedium,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.colored(AppColors.coral),
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Save Changes",
                    style: AppTextStyles.buttonLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          "Log Out",
          style: AppTextStyles.buttonMedium.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text("Edit Profile", style: AppTextStyles.h4),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username field
              Text(
                "Username",
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Enter your username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Style Bio field
              Text(
                "Style Bio",
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 150,
                decoration: InputDecoration(
                  hintText: "Write your style bio...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Account Settings Section Header
              Text(
                "Account Settings",
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              // Change Password button
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          "Change Password",
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Profile Picture section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_a_photo, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          "Change Profile Picture",
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _saveProfile();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
            ),
            child: Text(
              "Save",
              style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text("Edit Username", style: AppTextStyles.h4),
        content: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
          ),
          child: TextField(
            controller: _usernameController,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: "Enter username",
              hintStyle: AppTextStyles.bodyMedium,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(
              "Save",
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: Text("Log Out", style: AppTextStyles.h4),
        content: Text(
          "Are you sure you want to end your session?",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              "Log Out",
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Business Portfolio Section for Tailors/Seamstresses
  Widget _buildBusinessPortfolioSection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Text(
          'Please log in to view your business portfolio',
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error;
          debugPrint('Error loading portfolio: $error');
          debugPrint('User UID: ${user.uid}');
          debugPrint('User Role: $_userRole');
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  'Error loading portfolio',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $error',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Portfolio loading...');
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        debugPrint('Portfolio connection state: ${snapshot.connectionState}');
        final posts = snapshot.data?.docs ?? [];
        debugPrint('Posts count: ${posts.length}');

        if (posts.isEmpty) {
          debugPrint('No posts found for user: ${user.uid}');
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Icon(Icons.style_outlined, size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Showcase Your Business',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share your designs and services to attract customers',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Edit Business Profile Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to business profile screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BusinessProfileScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: Text(
                            'Edit Business',
                            style: AppTextStyles.buttonMedium,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.md,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add to Portfolio Button
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to create post screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreatePostScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: Text(
                            'Add Portfolio',
                            style: AppTextStyles.buttonMedium,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppBorderRadius.md,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Portfolio Stats
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPortfolioStatItem(posts.length.toString(), "Designs"),
                  _buildPortfolioStatItem(
                    posts
                        .where((p) {
                          final likesList = p['likes'] as List?;
                          return likesList != null && likesList.isNotEmpty;
                        })
                        .length
                        .toString(),
                    "Popular",
                  ),
                ],
              ),
            ),

            // Portfolio Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index].data() as Map<String, dynamic>;
                final mediaUrls = post['mediaUrls'] as List? ?? [];
                final likes = (post['likes'] as List?)?.length ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    boxShadow: AppShadows.soft,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Media
                        if (mediaUrls.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              mediaUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                            ),
                          )
                        else
                          Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(
                              Icons.style,
                              color: AppColors.textTertiary,
                              size: 48,
                            ),
                          ),

                        // Overlay with likes and type
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                              stops: const [0.3, 0.6, 1.0],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Post type badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    borderRadius: BorderRadius.circular(
                                      AppBorderRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    post['postType'] == 'video'
                                        ? 'VIDEO'
                                        : 'DESIGN',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Likes
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      likes.toString(),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortfolioStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
