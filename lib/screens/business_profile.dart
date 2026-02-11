import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import '../models/tailor_profile.dart';
import '../services/profile_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late ProfileService profileService;
  late CloudinaryService cloudinaryService;
  TailorProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  double? _latitude;
  double? _longitude;

  // Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    profileService = ProfileService();
    cloudinaryService = CloudinaryService();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _businessNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _instagramController = TextEditingController();
    _bioController = TextEditingController();
  }

  void _populateControllers(TailorProfile profile) {
    _businessNameController.text = profile.businessName;
    _descriptionController.text = profile.businessDescription ?? '';
    _phoneController.text = profile.phoneNumber ?? '';
    _emailController.text = profile.email ?? '';
    _locationController.text = profile.location ?? '';
    _latitude = profile.latitude;
    _longitude = profile.longitude;
    _instagramController.text = profile.instagramHandle ?? '';
    _bioController.text = profile.bio ?? '';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await profileService.getCurrentTailorProfile();
      setState(() {
        _profile = profile;
        if (profile != null) {
          _populateControllers(profile);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (_profile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.business,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  const Text('No profile found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _createNewProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Create Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner section
                  _buildBannerSection(),
                  const SizedBox(height: 24),

                  // Business info section
                  _buildSection('Business Information', [
                    _buildEditableField(
                      label: 'Business Name',
                      controller: _businessNameController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Description',
                      controller: _descriptionController,
                      enabled: _isEditing,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Bio',
                      controller: _bioController,
                      enabled: _isEditing,
                      maxLines: 2,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Contact info section
                  _buildSection('Contact Information', [
                    _buildEditableField(
                      label: 'Phone Number',
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Location',
                      controller: _locationController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildEditableField(
                      label: 'Instagram Handle',
                      controller: _instagramController,
                      enabled: _isEditing,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Portfolio section
                  _buildPortfolioSection(),
                  const SizedBox(height: 24),

                  // Business hours section
                  _buildBusinessHoursSection(),
                  const SizedBox(height: 24),

                  // Stats section
                  if (_profile!.rating != null || _profile!.totalOrders != null)
                    _buildStatsSection(),

                  // Edit buttons
                  if (_isEditing) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _loadProfile();
                              setState(() => _isEditing = false);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBannerSection() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _profile?.bannerImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _profile!.bannerImageUrl!,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  if (_isEditing)
                    TextButton(
                      onPressed: _uploadBannerImage,
                      child: const Text('Upload Banner Image'),
                    )
                  else
                    const Text('No banner image'),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            suffixIcon: label.toLowerCase() == 'location' && enabled
                ? IconButton(
                    icon: const Icon(Icons.my_location_outlined),
                    onPressed: _useCurrentLocation,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _useCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable it from settings.',
              ),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _latitude = pos.latitude;
      _longitude = pos.longitude;
      _locationController.text =
          '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Location captured')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    }
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Portfolio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_profile!.portfolioImageUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount:
                _profile!.portfolioImageUrls.length + (_isEditing ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _profile!.portfolioImageUrls.length && _isEditing) {
                return GestureDetector(
                  onTap: _uploadPortfolioImage,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                );
              }
              return GestureDetector(
                onLongPress: _isEditing
                    ? () => _removePortfolioImage(
                        _profile!.portfolioImageUrls[index],
                      )
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_profile!.portfolioImageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          )
        else if (_isEditing)
          GestureDetector(
            onTap: _uploadPortfolioImage,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text('Add Portfolio Images'),
                ],
              ),
            ),
          )
        else
          const Text('No portfolio images yet'),
      ],
    );
  }

  Widget _buildBusinessHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Hours',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_profile!.businessHours.isNotEmpty)
          Column(
            children: _profile!.businessHours
                .map(
                  (hours) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            hours.dayOfWeek,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            hours.isOpen
                                ? '${hours.openTime} - ${hours.closeTime}'
                                : 'Closed',
                            style: TextStyle(
                              fontSize: 13,
                              color: hours.isOpen
                                  ? AppColors.textSecondary
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        else
          const Text('No business hours set'),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (_profile!.rating != null)
            Column(
              children: [
                Text(
                  _profile!.rating!.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Rating',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          if (_profile!.totalOrders != null)
            Column(
              children: [
                Text(
                  _profile!.totalOrders!.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Orders',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _uploadBannerImage() async {
    // TODO: Implement image upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image upload feature coming soon')),
    );
  }

  Future<void> _uploadPortfolioImage() async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Show dialog for Cloudinary URL
        final TextEditingController urlController = TextEditingController();

        if (mounted) {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Add Cloudinary Image URL'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Paste your Cloudinary image URL here.\n\nExample: https://res.cloudinary.com/...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urlController,
                    decoration: InputDecoration(
                      hintText: 'https://res.cloudinary.com/...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    if (url.isNotEmpty && url.startsWith('http')) {
                      Navigator.pop(dialogContext);

                      // Add to profile
                      try {
                        final uid = profileService.getCurrentUserId() ?? '';
                        await profileService.addPortfolioImage(uid, url);

                        // Reload profile
                        await _loadProfile();

                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Image added to portfolio!'),
                            backgroundColor: Color(0xFF2D6A4F),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding image: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid Cloudinary URL'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _removePortfolioImage(String imageUrl) async {
    try {
      String uid = profileService.getCurrentUserId() ?? '';
      await profileService.removePortfolioImage(uid, imageUrl);

      // Reload profile
      await _loadProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final uid = profileService.getCurrentUserId();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      }
      return;
    }

    final name = _businessNameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business name is required')),
        );
      }
      return;
    }

    final updates = <String, dynamic>{
      'businessName': name,
      'businessDescription': _descriptionController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'location': _locationController.text.trim(),
      'instagramHandle': _instagramController.text.trim(),
      'bio': _bioController.text.trim(),
      'updatedAt': DateTime.now(),
    };

    if (_latitude != null && _longitude != null) {
      updates['latitude'] = _latitude;
      updates['longitude'] = _longitude;
    }

    try {
      await profileService.updateTailorProfileFields(uid, updates);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  Future<void> _createNewProfile() async {
    final uid = profileService.getCurrentUserId();
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      }
      return;
    }

    final name = _businessNameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business name is required')),
        );
      }
      return;
    }

    final profile = TailorProfile(
      uid: uid,
      businessName: name,
      businessDescription: _descriptionController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      location: _locationController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      instagramHandle: _instagramController.text.trim(),
      bio: _bioController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await profileService.saveTailorProfile(profile);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile created'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
      setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating profile: $e')));
      }
    }
  }
}
