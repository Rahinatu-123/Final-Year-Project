import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isPortfolioBusy = false;
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
      floatingActionButton: (!_isLoading && _profile != null)
          ? FloatingActionButton.extended(
              onPressed: _isPortfolioBusy ? null : _showPortfolioAddOptions,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add To Portfolio'),
            )
          : null,
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

  Future<void> _showPortfolioAddOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text(
                  'Add To Portfolio',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Add Design (No Post Needed)'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _uploadPortfolioImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.post_add),
                title: const Text('Add From My Posts'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddFromPostsSheet();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
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
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
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
    final uid = profileService.getCurrentUserId();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Portfolio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_isPortfolioBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _isPortfolioBusy ? null : _uploadPortfolioImage,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add Design'),
            ),
            OutlinedButton.icon(
              onPressed: _isPortfolioBusy ? null : _showAddFromPostsSheet,
              icon: const Icon(Icons.post_add, size: 18),
              label: const Text('Add From My Posts'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'You can upload designs directly here without posting.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        if (uid == null)
          const Text('Please login to manage portfolio')
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tailor_portfolio')
                .where('tailorId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final items = snapshot.data?.docs ?? [];
              if (items.isEmpty) {
                return const Text('No portfolio items yet');
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final data = items[index].data() as Map<String, dynamic>;
                  final imageUrl = (data['imageUrl'] ?? '').toString();
                  final description = (data['description'] ?? '').toString();

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            description.isEmpty
                                ? 'No description'
                                : description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
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

      if (pickedFile == null) return;

      final uid = profileService.getCurrentUserId();
      if (uid == null) return;

      final description = await _askPortfolioDescription();
      if (description == null) return;

      setState(() => _isPortfolioBusy = true);
      final uploadedUrl = await cloudinaryService.uploadImage(
        File(pickedFile.path),
      );

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        throw Exception('Upload failed. Please try again.');
      }

      await profileService.addPortfolioItem(
        uid: uid,
        imageUrl: uploadedUrl,
        description: description,
      );
      await _loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Design added to portfolio'),
          backgroundColor: Color(0xFF2D6A4F),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPortfolioBusy = false);
      }
    }
  }

  Future<String?> _askPortfolioDescription({String initialValue = ''}) async {
    final controller = TextEditingController(text: initialValue);

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Portfolio Description'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a short description',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddFromPostsSheet() async {
    final uid = profileService.getCurrentUserId();
    if (uid == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.75,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Add From My Posts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: uid)
                        .limit(40)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading posts: ${snapshot.error}'),
                        );
                      }

                      final docs = [...(snapshot.data?.docs ?? [])]
                        ..sort((a, b) {
                          final aTs =
                              (a.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          final bTs =
                              (b.data() as Map<String, dynamic>)['timestamp']
                                  as Timestamp?;
                          final aMs = aTs?.millisecondsSinceEpoch ?? 0;
                          final bMs = bTs?.millisecondsSinceEpoch ?? 0;
                          return bMs.compareTo(aMs);
                        });
                      if (docs.isEmpty) {
                        return const Center(child: Text('No posts found yet'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: docs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final imageUrls = _extractImageUrlsFromPost(data);
                          final caption = (data['content'] ?? '').toString();

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrls.isNotEmpty
                                      ? Image.network(
                                          imageUrls.first,
                                          width: 62,
                                          height: 62,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Container(
                                                width: 62,
                                                height: 62,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          width: 62,
                                          height: 62,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.videocam),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        caption.isEmpty
                                            ? '(No caption)'
                                            : caption,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        imageUrls.isEmpty
                                            ? 'No image in this post'
                                            : '${imageUrls.length} image(s) available',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: imageUrls.isEmpty
                                      ? null
                                      : () async {
                                          try {
                                            final desc =
                                                await _askPortfolioDescription(
                                                  initialValue: caption,
                                                );
                                            if (desc == null) return;

                                            setState(
                                              () => _isPortfolioBusy = true,
                                            );
                                            await profileService
                                                .addPortfolioItems(
                                                  uid: uid,
                                                  imageUrls: imageUrls,
                                                  description: desc,
                                                );
                                            if (mounted) {
                                              Navigator.pop(sheetContext);
                                            }
                                            await _loadProfile();
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Added ${imageUrls.length} image(s) from post',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF2D6A4F,
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Failed to add from post: $e',
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _isPortfolioBusy = false,
                                              );
                                            }
                                          }
                                        },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _extractImageUrlsFromPost(Map<String, dynamic> postData) {
    final rawMedia = postData['mediaUrls'] as List<dynamic>? ?? [];
    final urls = rawMedia.map((e) => e.toString()).toList();

    return urls
        .where((url) {
          final lower = url.toLowerCase();
          return lower.contains('/image/upload/') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp');
        })
        .toSet()
        .toList();
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
