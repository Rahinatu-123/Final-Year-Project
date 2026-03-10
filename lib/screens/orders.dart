import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/custom_order.dart';
import '../services/cloudinary_service.dart';
import '../services/custom_order_service.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  final String tailorId;
  final String clientId;
  final String clientName;
  final bool isFabricSeller;

  const OrdersScreen({
    Key? key,
    required this.tailorId,
    required this.clientId,
    required this.clientName,
    this.isFabricSeller = false,
  }) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late CustomOrderService orderService;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _measurementsController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(
    text: '7',
  );

  @override
  void initState() {
    super.initState();
    orderService = CustomOrderService();
  }

  @override
  void dispose() {
    _styleController.dispose();
    _measurementsController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemLabel = _itemLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} - Orders'),
        backgroundColor: AppColors.primary,
        elevation: 1,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('custom_orders')
            .where('clientId', isEqualTo: widget.clientId)
            .where('tailorId', isEqualTo: widget.tailorId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Orders will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs
              .map(
                (doc) => CustomOrder.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          // Sort by createdAt in memory (descending - newest first)
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length + 2,
            itemBuilder: (context, index) {
              // First item: Custom Orders Header
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isFabricSeller
                                ? 'Fabric Orders'
                                : 'Custom Orders',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              orders.length.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              // Second item: Summary card
              if (index == 1) {
                final activeOrders = orders
                    .where((o) => o.status == CustomOrderStatus.active)
                    .toList();
                if (activeOrders.isEmpty) {
                  return const SizedBox.shrink();
                }

                final nextDueOrder = activeOrders.isNotEmpty
                    ? activeOrders.reduce(
                        (a, b) =>
                            (a.dueDate ?? a.createdAt).isBefore(
                              b.dueDate ?? b.createdAt,
                            )
                            ? a
                            : b,
                      )
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders: ${activeOrders.length}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (nextDueOrder != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Next Deadline',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${nextDueOrder.daysRemaining()} days remaining for ${nextDueOrder.style}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                );
              }

              final order = orders[index - 2];
              return OrderDetailCard(
                order: order,
                onTap: () {
                  _showOrderDialog(existingOrder: order);
                },
                onEdit: () => _showOrderDialog(existingOrder: order),
                onToggleComplete: () async {
                  try {
                    if (order.status == CustomOrderStatus.active) {
                      await orderService.markAsDelivered(order.id);
                    } else if (order.status == CustomOrderStatus.delivered) {
                      final reopened = order.copyWith(
                        status: CustomOrderStatus.active,
                        completedAt: null,
                      );
                      await orderService.updateCustomOrder(reopened);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Status update failed: $e')),
                      );
                    }
                  }
                },
                onDelete: () async {
                  final confirm = await _showDeleteConfirmation();
                  if (confirm) {
                    try {
                      await orderService.deleteOrder(order.id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Order'),
            content: const Text('Are you sure you want to delete this order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showOrderDialog({CustomOrder? existingOrder}) async {
    final isEdit = existingOrder != null;
    final itemLabel = _itemLabel;
    final galleryLabel = _galleryLabel;

    _styleController.text =
        existingOrder?.style == 'Custom style' ||
            existingOrder?.style == 'Custom fabric'
        ? ''
        : (existingOrder?.style ?? '');
    _measurementsController.text = existingOrder?.measurements == 'Not provided'
        ? ''
        : (existingOrder?.measurements ?? '');
    _quantityController.text = widget.isFabricSeller
        ? _extractFabricQuantity(existingOrder?.measurements ?? '')
        : '';
    _priceController.text = existingOrder == null
        ? ''
        : existingOrder.basePrice.toString();
    _daysController.text = existingOrder?.daysToDeliver.toString() ?? '7';

    File? selectedStyleImage;
    String? existingStyleImageUrl = existingOrder?.styleImageUrl;

    Future<void> selectStyleFromGallery(
      void Function(void Function()) setDialogState,
    ) async {
      final selectedUrl = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(0),
          child: _OrderStyleGallerySelector(
            onStyleSelected: (url) => Navigator.pop(context, url),
          ),
        ),
      );

      if (selectedUrl != null && selectedUrl.isNotEmpty) {
        setDialogState(() {
          selectedStyleImage = null;
          existingStyleImageUrl = selectedUrl;
        });
      }
    }

    Future<void> pickStyleImage(
      ImageSource source,
      void Function(void Function()) setDialogState,
    ) async {
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: source,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85,
        );

        if (picked != null) {
          setDialogState(() {
            selectedStyleImage = File(picked.path);
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unable to pick image: $e')));
        }
      }
    }

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: size.width * 0.92,
            height: size.height * 0.78,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.isFabricSeller
                            ? (isEdit
                                  ? 'Edit Fabric Order'
                                  : 'Add Fabric Order')
                            : (isEdit
                                  ? 'Edit Order (All Fields Optional)'
                                  : 'Add Order (All Fields Optional)'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _styleController,
                              decoration: InputDecoration(
                                labelText: '$itemLabel (optional)',
                                hintText: widget.isFabricSeller
                                    ? 'e.g., Ankara Cotton'
                                    : 'e.g., Dress',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _measurementsController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: widget.isFabricSeller
                                    ? 'Fabric Details (optional)'
                                    : 'Measurements (optional)',
                                hintText: widget.isFabricSeller
                                    ? 'Color, pattern, width, notes'
                                    : 'Chest: 36, Waist: 30',
                              ),
                            ),
                            if (widget.isFabricSeller) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _quantityController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Quantity (yards, optional)',
                                  hintText: 'e.g., 5.5',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Price (GHc, optional)',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _daysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Days to Deliver (optional)',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.isFabricSeller
                                  ? 'Fabric Reference Image (optional)'
                                  : '$itemLabel Image (optional)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (selectedStyleImage != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  selectedStyleImage!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else if (existingStyleImageUrl != null &&
                                existingStyleImageUrl!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  existingStyleImageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 120,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.primary.withOpacity(
                                            0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Image not available'),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.3),
                                  ),
                                  color: AppColors.primary.withOpacity(0.06),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'No ${itemLabel.toLowerCase()} image selected',
                                ),
                              ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      selectStyleFromGallery(setDialogState),
                                  icon: const Icon(Icons.collections),
                                  label: Text(galleryLabel),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => pickStyleImage(
                                    ImageSource.gallery,
                                    setDialogState,
                                  ),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => pickStyleImage(
                                    ImageSource.camera,
                                    setDialogState,
                                  ),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Camera'),
                                ),
                                if (selectedStyleImage != null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedStyleImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                                if (existingStyleImageUrl != null &&
                                    existingStyleImageUrl!.isNotEmpty &&
                                    selectedStyleImage == null)
                                  TextButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        existingStyleImageUrl = null;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove Current'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                              ),
                              child: Text(isEdit ? 'Update' : 'Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (shouldSave != true) return;

    final style = _styleController.text.trim().isEmpty
        ? (widget.isFabricSeller ? 'Custom fabric' : 'Custom style')
        : _styleController.text.trim();
    final measurements = widget.isFabricSeller
        ? _buildFabricDetails(
            details: _measurementsController.text.trim(),
            quantityYards: _quantityController.text.trim(),
          )
        : (_measurementsController.text.trim().isEmpty
              ? 'Not provided'
              : _measurementsController.text.trim());
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final parsedDays = int.tryParse(_daysController.text.trim()) ?? 7;
    final days = parsedDays <= 0 ? 7 : parsedDays;

    try {
      String? styleImageUrl;
      if (selectedStyleImage != null) {
        styleImageUrl = await _uploadStyleImage(selectedStyleImage!);
        if (styleImageUrl == null) {
          return;
        }
      } else {
        styleImageUrl = existingStyleImageUrl;
      }

      if (isEdit) {
        final updatedOrder = existingOrder.copyWith(
          style: style,
          styleImageUrl: styleImageUrl,
          basePrice: price,
          measurements: measurements,
          daysToDeliver: days,
          dueDate: DateTime.now().add(Duration(days: days)),
        );
        await orderService.updateCustomOrder(updatedOrder);
      } else {
        final order = CustomOrder(
          id: '',
          tailorId: widget.tailorId,
          clientName: widget.clientName,
          clientId: widget.clientId,
          style: style,
          styleImageUrl: styleImageUrl,
          basePrice: price,
          measurements: measurements,
          daysToDeliver: days,
          createdAt: DateTime.now(),
          dueDate: DateTime.now().add(Duration(days: days)),
        );
        await orderService.createCustomOrder(order);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Order updated successfully.'
                  : 'Order added for this client.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add order: $e')));
      }
    }
  }

  Future<String?> _uploadStyleImage(File file) async {
    try {
      // Upload direct phone images to Cloudinary.
      final imageUrl = await _cloudinaryService.uploadImage(file);
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Cloudinary upload returned an empty URL.');
      }

      // Best-effort metadata write; do not fail order creation if rules deny it.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await _cloudinaryService.saveCloudinaryImageUrl(
            imageUrl: imageUrl,
            imageType: 'order',
            referenceId: currentUser.uid,
          );
        } catch (e) {
          debugPrint('Skipping cloudinary_images metadata write: $e');
        }
      }

      return imageUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cloudinary upload failed: $e')));
      }
      return null;
    }
  }

  String get _itemLabel => widget.isFabricSeller ? 'Fabric' : 'Style';

  String get _galleryLabel =>
      widget.isFabricSeller ? 'Fabric Gallery' : 'Style Gallery';

  String _buildFabricDetails({
    required String details,
    required String quantityYards,
  }) {
    final cleanDetails = details.trim();
    final cleanQty = quantityYards.trim();

    if (cleanDetails.isEmpty && cleanQty.isEmpty) {
      return 'Not provided';
    }
    if (cleanDetails.isEmpty) {
      return 'Qty: $cleanQty yards';
    }
    if (cleanQty.isEmpty) {
      return cleanDetails;
    }
    return '$cleanDetails | Qty: $cleanQty yards';
  }

  String _extractFabricQuantity(String measurementText) {
    final regex = RegExp(
      r'Qty:\s*([0-9]+(?:\.[0-9]+)?)\s*yards',
      caseSensitive: false,
    );
    final match = regex.firstMatch(measurementText);
    return match?.group(1) ?? '';
  }
}

class OrderDetailCard extends StatelessWidget {
  final CustomOrder order;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const OrderDetailCard({
    Key? key,
    required this.order,
    required this.onTap,
    required this.onEdit,
    required this.onToggleComplete,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final urgency = order.getDeliveryUrgency();
    final urgencyColor = _getUrgencyColor(urgency);
    final daysRemaining = order.daysRemaining();
    final progressPercent = order.daysToDeliver <= 0
        ? 0.0
        : ((order.daysToDeliver - daysRemaining) / order.daysToDeliver) * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: urgencyColor.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Style Image
            if (order.styleImageUrl != null && order.styleImageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(color: urgencyColor.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                  child: Image.network(
                    order.styleImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.style,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.measurements,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GH₵${order.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: urgencyColor,
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: onEdit,
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: onToggleComplete,
                                child: Row(
                                  children: [
                                    Icon(
                                      order.status == CustomOrderStatus.active
                                          ? Icons.check_circle_outline
                                          : Icons.restore,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      order.status == CustomOrderStatus.active
                                          ? 'Mark Complete'
                                          : 'Mark Active',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: onDelete,
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            child: const Icon(Icons.more_vert, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Timeline
                  Text(
                    'Timeline: $daysRemaining days remaining',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: urgencyColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      minHeight: 6,
                      backgroundColor: urgencyColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Due date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: urgencyColor),
                      const SizedBox(width: 6),
                      Text(
                        'Due: ${order.dueDate != null ? _formatDate(order.dueDate!) : 'Not set'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: urgencyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  const Text(
                    'Order Timeline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTimeline(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final isCompleted = order.status == CustomOrderStatus.delivered;
    final orderedDate = order.createdAt;
    final due = order.dueDate;

    return Column(
      children: [
        _timelineItem(title: 'Ordered', date: orderedDate, done: true),
        _timelineLine(),
        _timelineItem(
          title: 'In Progress',
          date: isCompleted ? (order.completedAt ?? due ?? orderedDate) : due,
          done: true,
        ),
        _timelineLine(),
        _timelineItem(
          title: 'Completed',
          date: order.completedAt,
          done: isCompleted,
        ),
      ],
    );
  }

  Widget _timelineItem({
    required String title,
    required DateTime? date,
    required bool done,
  }) {
    final color = done ? AppColors.primary : Colors.grey;
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Text(
          date != null ? _formatDate(date) : '-',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _timelineLine() {
    return Container(
      margin: const EdgeInsets.only(left: 7, top: 2, bottom: 2),
      width: 2,
      height: 14,
      color: AppColors.primary.withOpacity(0.25),
    );
  }
}

class _OrderStyleGallerySelector extends StatefulWidget {
  final ValueChanged<String> onStyleSelected;

  const _OrderStyleGallerySelector({required this.onStyleSelected});

  @override
  State<_OrderStyleGallerySelector> createState() =>
      _OrderStyleGallerySelectorState();
}

class _OrderStyleGallerySelectorState
    extends State<_OrderStyleGallerySelector> {
  int _selectedCategoryIndex = 0;

  List<String> get _categories => [
    'All',
    'long dress',
    'short dress',
    'ladies top',
    'top and down',
    'bridal kenta',
    'jumpsuit',
    'lace',
    'kaba and slit',
    'men',
    'couple',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categories[_selectedCategoryIndex];
    final query = selectedCategory == 'All'
        ? FirebaseFirestore.instance.collection('styles')
        : FirebaseFirestore.instance
              .collection('styles')
              .where('category', isEqualTo: selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Style'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final selected = index == _selectedCategoryIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No styles found'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final imageUrl = (data['imageUrl'] as String?) ?? '';

                    return GestureDetector(
                      onTap: imageUrl.isEmpty
                          ? null
                          : () => widget.onStyleSelected(imageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imageUrl.isEmpty
                            ? Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              )
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Color _getUrgencyColor(DeliveryUrgency urgency) {
  switch (urgency) {
    case DeliveryUrgency.green:
      return const Color(0xFF2D6A4F);
    case DeliveryUrgency.yellow:
      return const Color(0xFFE8A855);
    case DeliveryUrgency.red:
      return const Color(0xFFBA1A1A);
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final dateOnly = DateTime(date.year, date.month, date.day);
  if (dateOnly == today) {
    return 'Today';
  } else if (dateOnly == tomorrow) {
    return 'Tomorrow';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
