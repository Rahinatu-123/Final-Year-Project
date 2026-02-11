import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/fabric_seller.dart';
import '../services/fabric_seller_service.dart';

class FabricSellerShopProfile extends StatefulWidget {
  final String sellerId;

  const FabricSellerShopProfile({super.key, required this.sellerId});

  @override
  State<FabricSellerShopProfile> createState() =>
      _FabricSellerShopProfileState();
}

class _FabricSellerShopProfileState extends State<FabricSellerShopProfile> {
  final FabricSellerService _fabricService = FabricSellerService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  FabricSeller? _seller;

  // Form Controllers
  late TextEditingController _shopNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _businessHoursController;
  late TextEditingController _returnPolicyController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadProfile();
  }

  void _initializeControllers() {
    _shopNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _businessHoursController = TextEditingController();
    _returnPolicyController = TextEditingController();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final seller = await _fabricService.getSellerProfile(widget.sellerId);
      setState(() {
        _seller = seller;
        if (_seller != null) {
          _shopNameController.text = _seller!.shopName;
          _descriptionController.text = _seller!.description;
          _emailController.text = _seller!.email;
          _phoneController.text = _seller!.phoneNumber;
          _locationController.text = _seller!.location;
          _businessHoursController.text = _seller!.businessHours;
          _returnPolicyController.text = _seller!.returnExchangePolicy;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isLoading && _seller != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    setState(() => _isEditing = !_isEditing);
                  },
                  child: Text(_isEditing ? 'Cancel' : 'Edit'),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seller == null
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _isEditing ? _buildEditForm() : _buildViewProfile(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Shop Profile',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your shop profile to start selling',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() => _isEditing = true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Create Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildViewProfile() {
    if (_seller == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Header
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _seller!.shopName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _seller!.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                if (_seller!.isVerified)
                  Wrap(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Verified Seller'),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Business Information
        _buildInfoSection('Business Information', [
          _buildInfoTile('Email', _seller!.email, Icons.email),
          _buildInfoTile('Phone', _seller!.phoneNumber, Icons.phone),
          _buildInfoTile('Location', _seller!.location, Icons.location_on),
          _buildInfoTile(
            'Business Hours',
            _seller!.businessHours,
            Icons.schedule,
          ),
        ]),
        const SizedBox(height: 24),
        // Delivery Areas
        _buildSection('Delivery Areas', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _seller!.deliveryAreas.map((area) {
              return Chip(label: Text(area));
            }).toList(),
          ),
        ]),
        const SizedBox(height: 24),
        // Payment Methods
        _buildSection('Payment Methods', [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _seller!.paymentMethods.map((method) {
              return Chip(label: Text(method));
            }).toList(),
          ),
        ]),
        const SizedBox(height: 24),
        // Return Policy
        _buildSection('Return/Exchange Policy', [
          Text(
            _seller!.returnExchangePolicy,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ]),
        const SizedBox(height: 24),
        // Stats
        if (_seller!.totalSales != null && _seller!.totalSales! > 0)
          _buildSection('Statistics', [
            _buildStatRow('Total Sales', '${_seller!.totalSales}'),
            _buildStatRow('Reviews', '${_seller!.totalReviews}'),
            _buildStatRow(
              'Rating',
              '${_seller!.averageRating?.toStringAsFixed(1)} ⭐',
            ),
          ]),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Name
          TextFormField(
            controller: _shopNameController,
            decoration: InputDecoration(
              labelText: 'Shop Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter shop name' : null,
          ),
          const SizedBox(height: 16),
          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Shop Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter description' : null,
          ),
          const SizedBox(height: 16),
          // Email
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) => value?.isEmpty ?? true ? 'Enter email' : null,
          ),
          const SizedBox(height: 16),
          // Phone
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter phone number' : null,
          ),
          const SizedBox(height: 16),
          // Location
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Enter location' : null,
          ),
          const SizedBox(height: 16),
          // Business Hours
          TextFormField(
            controller: _businessHoursController,
            decoration: InputDecoration(
              labelText: 'Business Hours',
              hintText: 'e.g., 9 AM - 6 PM, Mon-Sat',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Return Policy
          TextFormField(
            controller: _returnPolicyController,
            decoration: InputDecoration(
              labelText: 'Return/Exchange Policy',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Save Profile'),
            ),
          ),
          const SizedBox(height: 16),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final seller = FabricSeller(
        id: widget.sellerId,
        userId: FirebaseAuth.instance.currentUser!.uid,
        shopName: _shopNameController.text,
        description: _descriptionController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        location: _locationController.text,
        deliveryAreas: _seller?.deliveryAreas ?? [],
        businessHours: _businessHoursController.text,
        paymentMethods: _seller?.paymentMethods ?? [],
        returnExchangePolicy: _returnPolicyController.text,
        createdAt: _seller?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _fabricService.saveFabricSellerProfile(seller);

      if (mounted) {
        setState(() {
          _seller = seller;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return _buildSection(title, children);
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _businessHoursController.dispose();
    _returnPolicyController.dispose();
    super.dispose();
  }
}
