import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/shop_order.dart';
import '../services/shop_order_service.dart';
import '../theme/app_theme.dart';

class CreateShopOrderScreen extends StatefulWidget {
  final Product product;
  final String tailorId;

  const CreateShopOrderScreen({
    super.key,
    required this.product,
    required this.tailorId,
  });

  @override
  State<CreateShopOrderScreen> createState() => _CreateShopOrderScreenState();
}

class _CreateShopOrderScreenState extends State<CreateShopOrderScreen> {
  late ShopOrderService _orderService;
  late TextEditingController _quantityController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _zipController;
  late TextEditingController _notesController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _orderService = ShopOrderService();
    _quantityController = TextEditingController(text: '1');
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _zipController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (_addressController.text.isEmpty || _cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in shipping address')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Validate price first
    if (widget.product.price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product price is invalid. Please contact the seller.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final quantityText = _quantityController.text.trim();
      if (quantityText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a quantity')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final quantity = int.parse(quantityText);

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quantity must be at least 1')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      const uuid = Uuid();

      final order = ShopOrder(
        id: uuid.v4(),
        customerId: currentUser.uid,
        tailorId: widget.tailorId,
        productId: widget.product.id,
        productName: widget.product.name,
        productImages: widget.product.imageUrls,
        productPrice: widget.product.price,
        discountedPrice: widget.product.discountedPrice,
        quantity: quantity,
        color: null,
        size: null,
        customizations: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        status: ShopOrderStatus.pending,
        createdAt: DateTime.now(),
        shippingAddress: _addressController.text,
        shippingCity: _cityController.text,
        shippingZipCode: _zipController.text,
        estimatedDelivery: DateTime.now().add(const Duration(days: 14)),
      );

      await _orderService.createOrder(order);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Product'),
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
            // Product Preview
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.surface,
              ),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: widget.product.imageUrls.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                widget.product.imageUrls.first,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.product.name, style: AppTextStyles.h4),
                        const SizedBox(height: 8),
                        Text(
                          widget.product.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              'GHS ${widget.product.price.toStringAsFixed(2)}',
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.product.discountedPrice != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'GHS ${widget.product.discountedPrice!.toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quantity
            Text('Quantity', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Shipping Address
            Text('Shipping Address', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Street address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _zipController,
              decoration: InputDecoration(
                hintText: 'Zip Code (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Special Requests
            Text('Special Requests (Optional)', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Any special customizations or requests?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Order Summary
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceVariant),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unit Price:', style: AppTextStyles.bodyMedium),
                      Text(
                        'GHS ${(widget.product.discountedPrice ?? widget.product.price).toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color:
                              (widget.product.discountedPrice ??
                                      widget.product.price) <=
                                  0
                              ? Colors.red
                              : AppColors.textSecondary,
                          fontWeight:
                              (widget.product.discountedPrice ??
                                      widget.product.price) <=
                                  0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  if ((widget.product.discountedPrice ??
                          widget.product.price) <=
                      0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Invalid price. Contact seller to set product price.',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Quantity:', style: AppTextStyles.bodyMedium),
                      Text(
                        _quantityController.text,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: AppTextStyles.h4),
                      Text(
                        'GHS ${((widget.product.discountedPrice ?? widget.product.price) * double.parse(_quantityController.text)).toStringAsFixed(2)}',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: AppColors.textTertiary,
                ),
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Place Order'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
