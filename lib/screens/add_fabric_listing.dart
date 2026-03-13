import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/fabric.dart';
import '../services/fabric_seller_service.dart';

class AddFabricListing extends StatefulWidget {
  final String sellerId;
  final Function()? onFabricAdded;

  const AddFabricListing({
    super.key,
    required this.sellerId,
    this.onFabricAdded,
  });

  @override
  State<AddFabricListing> createState() => _AddFabricListingState();
}

class _AddFabricListingState extends State<AddFabricListing> {
  final FabricSellerService _fabricService = FabricSellerService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form Fields
  FabricType _selectedType = FabricType.cotton;
  String _color = '';
  double _pricePerYard = 0;
  int _quantityAvailable = 0;
  double _fabricWidth = 0;
  List<String> _tags = [];
  List<String> _imageUrls = [];

  bool _isLoading = false;
  final String _sellerName = 'Fabric Seller'; // This should come from user profile

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Fabric'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload Section
                    _buildImageUploadSection(),
                    const SizedBox(height: 24),
                    // Fabric Type
                    Text(
                      'Fabric Type',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<FabricType>(
                      value: _selectedType,
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() => _selectedType = value!);
                      },
                      items: FabricType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Color
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter color' : null,
                      onChanged: (value) => _color = value,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    // Price
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Price per Yard',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter price' : null,
                      onChanged: (value) =>
                          _pricePerYard = double.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    // Quantity
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Quantity Available (yards)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter quantity' : null,
                      onChanged: (value) =>
                          _quantityAvailable = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    // Fabric Width
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Fabric Width (inches)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Enter fabric width' : null,
                      onChanged: (value) =>
                          _fabricWidth = double.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    // Tags
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Tags (comma-separated)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        _tags = value
                            .split(',')
                            .map((tag) => tag.trim())
                            .toList();
                      },
                    ),
                    const SizedBox(height: 24),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Add Fabric',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fabric Images',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_imageUrls.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: _imageUrls[index].startsWith('http')
                            ? NetworkImage(_imageUrls[index])
                            : FileImage(File(_imageUrls[index]))
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _imageUrls.removeAt(index));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Photos'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageUrls.add(image.path); // In production, upload to cloud storage
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fabric = Fabric(
        id: '',
        sellerId: widget.sellerId,
        sellerName: _sellerName,
        fabricType: _selectedType,
        color: _color,
        pattern: '',
        imageUrls: _imageUrls,
        pricePerYard: _pricePerYard,
        quantityAvailable: _quantityAvailable,
        fabricWidth: _fabricWidth,
        weight: '',
        texture: '',
        careInstructions: '',
        tags: _tags,
        createdAt: DateTime.now(),
      );

      await _fabricService.addFabric(fabric);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fabric added successfully!')),
        );
        widget.onFabricAdded?.call();
        _formKey.currentState?.reset();
        setState(() {
          _imageUrls = [];
          _color = '';
          _pricePerYard = 0;
          _quantityAvailable = 0;
          _fabricWidth = 0;
          _tags = [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding fabric: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
