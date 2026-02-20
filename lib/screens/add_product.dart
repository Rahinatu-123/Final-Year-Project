import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  final String sellerId;
  final Product? productToEdit;

  const AddProductScreen({
    super.key,
    required this.sellerId,
    this.productToEdit,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  late ProductService productService;
  late CloudinaryService cloudinaryService;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  ProductType selectedType = ProductType.clothes;
  String? selectedCategory;
  bool isSoldOut = false;
  bool isCustomizable = false;
  List<String> imageUrls = [];
  List<File> selectedImages = [];

  final List<String> clothesCategories = [
    'Bridal',
    'Traditional',
    'Men',
    'Lace',
    'Simple Wear',
  ];

  final List<String> fabricCategories = [
    'Cotton',
    'Silk',
    'Lace',
    'Ankara',
    'Denim',
    'Wool',
    'Polyester',
    'Linen',
    'Velvet',
    'Chiffon',
  ];

  @override
  void initState() {
    super.initState();
    productService = ProductService();
    cloudinaryService = CloudinaryService();

    if (widget.productToEdit != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final product = widget.productToEdit!;
    nameController.text = product.name;
    descriptionController.text = product.description;
    priceController.text = product.price.toString();
    discountPriceController.text = product.discountedPrice?.toString() ?? '';
    colorController.text = product.color ?? '';
    sizeController.text = product.size ?? '';
    selectedType = product.type;
    selectedCategory = product.category;
    isSoldOut = product.isSoldOut;
    isCustomizable = product.isCustomizable ?? false;
    imageUrls = product.imageUrls;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    discountPriceController.dispose();
    colorController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.productToEdit != null ? 'Edit Product' : 'Add Product',
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Type
            _buildSection(
              title: 'Product Type',
              child: Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(ProductType.clothes, 'Clothes'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeButton(ProductType.fabric, 'Fabric'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product Name
            _buildSection(
              title: 'Product Name',
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Enter product name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description
            _buildSection(
              title: 'Description',
              child: TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your product...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _buildSection(
              title: 'Category',
              child: DropdownButtonFormField<String>(
                value: selectedCategory,
                items:
                    (selectedType == ProductType.clothes
                            ? clothesCategories
                            : fabricCategories)
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() => selectedCategory = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  hintText: 'Select category',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Price Section
            Row(
              children: [
                Expanded(
                  child: _buildSection(
                    title: 'Price',
                    child: TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSection(
                    title: 'Discount Price',
                    child: TextField(
                      controller: discountPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₦ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color and Size (only for clothes)
            if (selectedType == ProductType.clothes) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSection(
                      title: 'Color',
                      child: TextField(
                        controller: colorController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Blue, Red',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSection(
                      title: 'Size',
                      child: TextField(
                        controller: sizeController,
                        decoration: InputDecoration(
                          hintText: 'e.g., M, L',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Customizable option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isCustomizable,
                      onChanged: (value) {
                        setState(() => isCustomizable = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text('This product can be customized'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sold Out option
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isSoldOut,
                    onChanged: (value) {
                      setState(() => isSoldOut = value ?? false);
                    },
                  ),
                  const Expanded(child: Text('Mark as sold out')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Images section
            _buildSection(
              title: 'Product Images',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display existing images
                  if (imageUrls.isNotEmpty) ...[
                    Text('Current Images:', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primary,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(imageUrls[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        imageUrls.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFBA1A1A),
                                        shape: BoxShape.circle,
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
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // New images from device
                  if (selectedImages.isNotEmpty) ...[
                    Text(
                      'New Images to Upload:',
                      style: AppTextStyles.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.accent),
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFBA1A1A),
                                        shape: BoxShape.circle,
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
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add image buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImageFromCamera(),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImageFromGallery(),
                          icon: const Icon(Icons.image),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.productToEdit != null
                      ? 'Update Product'
                      : 'Add Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTypeButton(ProductType type, String label) {
    final isSelected = selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedType = type;
          selectedCategory = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          selectedImages.addAll(images.map((img) => File(img.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (nameController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Upload new images
      List<String> uploadedUrls = [...imageUrls];
      for (var image in selectedImages) {
        final url = await cloudinaryService.uploadImage(image);
        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      // Fetch seller name from Firestore
      String sellerName = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.sellerId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          sellerName = userData['fullName'] ?? userData['name'] ?? 'Unknown';
        }
      } catch (e) {
        sellerName = 'Seller';
      }

      final double? discountPrice = discountPriceController.text.isEmpty
          ? null
          : double.tryParse(discountPriceController.text);

      final product = Product(
        id: widget.productToEdit?.id ?? '',
        sellerId: widget.sellerId,
        sellerName: sellerName,
        type: selectedType,
        name: nameController.text,
        description: descriptionController.text,
        imageUrls: uploadedUrls,
        price: double.parse(priceController.text),
        discountedPrice: discountPrice,
        discountPercent: _calculateDiscountPercent(
          double.parse(priceController.text),
          discountPrice,
        ),
        isSoldOut: isSoldOut,
        category: selectedCategory,
        color: colorController.text.isEmpty ? null : colorController.text,
        size: sizeController.text.isEmpty ? null : sizeController.text,
        isCustomizable: selectedType == ProductType.clothes
            ? isCustomizable
            : null,
        tags: [], // Can be extended later
        createdAt: widget.productToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.productToEdit != null) {
        // Update existing product
        await productService.updateProduct(product.id, product.toMap());
      } else {
        // Add new product
        await productService.addProduct(product);
      }

      Navigator.pop(context); // Close loading dialog
      Navigator.pop(context); // Close add product screen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.productToEdit != null
                ? 'Product updated successfully'
                : 'Product added successfully',
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  double? _calculateDiscountPercent(double original, double? discounted) {
    if (discounted != null && discounted < original) {
      return ((original - discounted) / original * 100);
    }
    return null;
  }
}
