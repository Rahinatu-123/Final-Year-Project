import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import 'landing_page.dart';

class CustomerProfile extends StatefulWidget {
  const CustomerProfile({super.key});

  @override
  State<CustomerProfile> createState() => _CustomerProfileState();
}

class _CustomerProfileState extends State<CustomerProfile> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _displayName = "Loading...";
  String? _photoUrl;
  String _userRole = "Member";
  bool _isLoading = true;
  bool _isSaving = false;

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
            _photoUrl = user.photoURL;
            _isLoading = false;
          });
        } else {
          setState(() {
            _displayName = user.displayName ?? "New User";
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

        setState(() {
          _displayName = _usernameController.text;
          _isSaving = false;
        });

        if (mounted) {
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
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _photoUrl = image.path);
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
                        // Stats row
                        _buildStatsRow(),
                        const SizedBox(height: 28),

                        Text("Account Settings", style: AppTextStyles.h4),
                        const SizedBox(height: 16),
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

                        const SizedBox(height: 28),
                        Text("Style Bio", style: AppTextStyles.h4),
                        const SizedBox(height: 16),
                        _buildDescriptionBox(),

                        const SizedBox(height: 32),
                        _buildSaveButton(),

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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          child: Column(
            children: [
              // Top row with back and settings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
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
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                      radius: 55,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: _photoUrl != null
                          ? (_photoUrl!.startsWith('http')
                                ? NetworkImage(_photoUrl!)
                                : FileImage(File(_photoUrl!)) as ImageProvider)
                          : null,
                      child: _photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name and role
              Text(
                _displayName,
                style: AppTextStyles.h3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Text(
                  _userRole,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
        children: [
          _buildStatItem("12", "Orders"),
          _buildDivider(),
          _buildStatItem("48", "Saved"),
          _buildDivider(),
          _buildStatItem("156", "Following"),
        ],
      ),
    );
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
}
