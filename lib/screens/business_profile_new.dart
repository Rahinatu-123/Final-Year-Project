import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/business_service.dart';
import '../theme/app_theme.dart';

class BusinessProfileScreenNew extends StatefulWidget {
  const BusinessProfileScreenNew({super.key});

  @override
  State<BusinessProfileScreenNew> createState() =>
      _BusinessProfileScreenNewState();
}

class _BusinessProfileScreenNewState extends State<BusinessProfileScreenNew> {
  late BusinessService _businessService;
  final _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  // Form data
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _instagramController = TextEditingController();
  final _bioController = TextEditingController();

  // Business data
  Map<String, dynamic>? _businessData;

  // Location data
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _businessService = BusinessService();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _businessService.getBusinessProfile();
    if (doc != null && doc.exists) {
      setState(() {
        _businessData = doc.data() as Map<String, dynamic>;
        _populateControllers();
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isEditing = true; // Start in edit mode if no profile exists
      });
    }
  }

  void _populateControllers() {
    if (_businessData == null) return;

    _businessNameController.text = _businessData!['businessName'] ?? '';
    _descriptionController.text = _businessData!['description'] ?? '';
    _phoneController.text = _businessData!['phone'] ?? '';
    _emailController.text = _businessData!['email'] ?? '';
    _locationController.text = _businessData!['location'] ?? '';
    _instagramController.text = _businessData!['instagram'] ?? '';
    _bioController.text = _businessData!['bio'] ?? '';

    // Load coordinates
    _latitude = _businessData!['latitude'];
    _longitude = _businessData!['longitude'];
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError(
          'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError(
          'Location permissions are permanently denied. Please enable them in app settings.',
        );
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _isGettingLocation = false;
      });

      _showSuccess('Location captured successfully!');
    } catch (e) {
      setState(() {
        _isGettingLocation = false;
      });
      _showError('Failed to get location: ${e.toString()}');
    }
  }

  Future<void> _saveBusinessProfile() async {
    if (_businessNameController.text.trim().isEmpty) {
      _showError('Please enter a business name');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String? logoUrl = _businessData?['logoUrl'];

    final success = await _businessService.saveBusinessProfile(
      businessName: _businessNameController.text.trim(),
      description: _descriptionController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      location: _locationController.text.trim(),
      instagram: _instagramController.text.trim(),
      bio: _bioController.text.trim(),
      logoUrl: logoUrl,
      latitude: _latitude,
      longitude: _longitude,
    );

    setState(() {
      _isSaving = false;
    });

    if (success) {
      _showSuccess('Business profile saved successfully!');
      setState(() {
        _isEditing = false;
      });
      _loadBusinessProfile(); // Reload to get updated data
    } else {
      _showError('Failed to save business profile');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _businessData == null
              ? 'Create Business Profile'
              : 'Business Profile',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_businessData != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Business Icon (non-interactive)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.business,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Form Fields or View Mode
                  if (_isEditing) ...[
                    _buildFormFields(),
                    const SizedBox(height: 30),
                    // Prominent Save Button at bottom
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBusinessProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 4,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.save, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'SAVE BUSINESS PROFILE',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    _buildViewMode(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          icon: Icons.business,
          required: true,
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          maxLines: 3,
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _phoneController,
          label: 'Phone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _locationController,
          label: 'Location',
          icon: Icons.location_on,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isGettingLocation)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Get Current Location',
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _instagramController,
          label: 'Instagram',
          icon: Icons.camera_alt,
        ),
        const SizedBox(height: 20),

        _buildTextField(
          controller: _bioController,
          label: 'Bio',
          icon: Icons.person,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon, color: AppColors.primary),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_businessData?['businessName'] != null) ...[
          _buildInfoRow('Business Name', _businessData!['businessName']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['description'] != null) ...[
          _buildInfoRow('Description', _businessData!['description']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['phone'] != null) ...[
          _buildInfoRow('Phone', _businessData!['phone']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['email'] != null) ...[
          _buildInfoRow('Email', _businessData!['email']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['location'] != null) ...[
          _buildInfoRow('Location', _businessData!['location']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['instagram'] != null) ...[
          _buildInfoRow('Instagram', _businessData!['instagram']),
          const SizedBox(height: 16),
        ],

        if (_businessData?['bio'] != null) ...[
          _buildInfoRow('Bio', _businessData!['bio']),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
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
}
