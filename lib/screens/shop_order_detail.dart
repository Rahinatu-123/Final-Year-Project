import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/shop_order.dart';
import '../services/shop_order_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';

class ShopOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final bool isForTailor;

  const ShopOrderDetailScreen({
    super.key,
    required this.orderId,
    required this.isForTailor,
  });

  @override
  State<ShopOrderDetailScreen> createState() => _ShopOrderDetailScreenState();
}

class _ShopOrderDetailScreenState extends State<ShopOrderDetailScreen> {
  late ShopOrderService _orderService;
  late CloudinaryService _cloudinaryService;
  late TextEditingController _notesController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _orderService = ShopOrderService();
    _cloudinaryService = CloudinaryService();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _uploadProgressImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isUpdating = true);

    try {
      final imageUrl = await _cloudinaryService.uploadImage(File(image.path));
      if (imageUrl != null) {
        await _orderService.addProgressImage(widget.orderId, imageUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress image uploaded')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateStatus(ShopOrderStatus newStatus) async {
    setState(() => _isUpdating = true);

    try {
      await _orderService.updateOrderStatus(widget.orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order marked as ${newStatus.toString().split('.').last}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _updateNotes() async {
    if (_notesController.text.isEmpty) return;

    setState(() => _isUpdating = true);

    try {
      await _orderService.updateTailorNotes(
        widget.orderId,
        _notesController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Notes updated')));
        _notesController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _statusToString(ShopOrderStatus status) {
    switch (status) {
      case ShopOrderStatus.pending:
        return 'Pending';
      case ShopOrderStatus.confirmed:
        return 'Confirmed';
      case ShopOrderStatus.inProgress:
        return 'In Progress';
      case ShopOrderStatus.ready:
        return 'Ready';
      case ShopOrderStatus.completed:
        return 'Completed';
      case ShopOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(ShopOrderStatus status) {
    switch (status) {
      case ShopOrderStatus.pending:
        return Colors.orange;
      case ShopOrderStatus.confirmed:
        return Colors.blue;
      case ShopOrderStatus.inProgress:
        return Colors.purple;
      case ShopOrderStatus.ready:
        return Colors.green;
      case ShopOrderStatus.completed:
        return Colors.green;
      case ShopOrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: FutureBuilder<ShopOrder?>(
        future: _orderService.getOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Order not found'));
          }

          final order = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor(order.status).withOpacity(0.1),
                    border: Border.all(
                      color: _statusColor(order.status),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _statusColor(order.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusToString(order.status),
                        style: AppTextStyles.h4.copyWith(
                          color: _statusColor(order.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.surfaceVariant,
                          image: order.productImages.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(
                                    order.productImages.first,
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productName,
                              style: AppTextStyles.h4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Qty: ${order.quantity}',
                              style: AppTextStyles.bodySmall,
                            ),
                            if (order.color != null)
                              Text(
                                'Color: ${order.color}',
                                style: AppTextStyles.bodySmall,
                              ),
                            if (order.size != null)
                              Text(
                                'Size: ${order.size}',
                                style: AppTextStyles.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timeline', style: AppTextStyles.h4),
                      const SizedBox(height: 16),
                      _buildTimelineItem('Ordered', order.createdAt, true),
                      _buildTimelineLine(),
                      _buildTimelineItem(
                        'Confirmed',
                        order.confirmedAt,
                        order.confirmedAt != null,
                      ),
                      _buildTimelineLine(),
                      _buildTimelineItem(
                        'In Progress',
                        order.startedAt,
                        order.startedAt != null,
                      ),
                      _buildTimelineLine(),
                      _buildTimelineItem(
                        'Ready',
                        order.estimatedDelivery,
                        order.status == ShopOrderStatus.ready ||
                            order.status == ShopOrderStatus.completed,
                      ),
                      _buildTimelineLine(),
                      _buildTimelineItem(
                        'Completed',
                        order.completedAt,
                        order.completedAt != null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Progress Images
                if (order.progressImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Progress Updates', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: order.progressImages.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _showImageDialog(order.progressImages[index]);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      order.progressImages[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                // Tailor Actions (only for tailor)
                if (widget.isForTailor)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tailor Actions', style: AppTextStyles.h4),
                        const SizedBox(height: 12),
                        // Status Buttons
                        if (order.status == ShopOrderStatus.pending)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(
                                      ShopOrderStatus.confirmed,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isUpdating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Confirm Order'),
                            ),
                          ),
                        if (order.status == ShopOrderStatus.confirmed)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(
                                      ShopOrderStatus.inProgress,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isUpdating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Start Production'),
                            ),
                          ),
                        if (order.status == ShopOrderStatus.inProgress)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(ShopOrderStatus.ready),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: _isUpdating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Mark as Ready'),
                            ),
                          ),
                        if (order.status == ShopOrderStatus.ready)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isUpdating
                                  ? null
                                  : () => _updateStatus(
                                      ShopOrderStatus.completed,
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: _isUpdating
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Complete Order'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Upload Progress Image
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isUpdating
                                ? null
                                : _uploadProgressImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Upload Progress Photo'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Tailor Notes
                        Text('Progress Notes', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Add production update...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isUpdating ? null : _updateNotes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Notes'),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Customer Cancel Button (only for customers, within 2 days and delivery > 5 days)
                if (!widget.isForTailor)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCancelSection(order),
                  ),

                const SizedBox(height: 24),

                // Order Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surfaceVariant),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unit Price:',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              'GHS ${order.productPrice.toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Quantity:', style: AppTextStyles.bodyMedium),
                            Text(
                              '${order.quantity}',
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
                              'GHS ${order.getTotalPrice().toStringAsFixed(2)}',
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem(String label, DateTime? date, bool isCompleted) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : AppColors.surfaceVariant,
            border: Border.all(
              color: isCompleted ? AppColors.primary : AppColors.textTertiary,
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMedium),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine() {
    return Padding(
      padding: const EdgeInsets.only(left: 9, top: 8, bottom: 8),
      child: Container(width: 2, height: 20, color: AppColors.surfaceVariant),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  Widget _buildCancelSection(ShopOrder order) {
    // Check if cancellation is allowed
    final orderAge = DateTime.now().difference(order.createdAt).inDays;
    final daysToDelivery =
        order.estimatedDelivery?.difference(DateTime.now()).inDays ?? 0;

    final canCancel =
        orderAge < 2 &&
        daysToDelivery > 5 &&
        (order.status == ShopOrderStatus.pending ||
            order.status == ShopOrderStatus.confirmed);

    if (!canCancel && order.status != ShopOrderStatus.cancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation Reason',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.coral),
            ),
            child: Text(
              orderAge >= 2
                  ? 'Orders can only be cancelled within 2 days.'
                  : daysToDelivery <= 5
                  ? 'Cancellation not available for orders with delivery within 5 days.'
                  : 'This order cannot be cancelled.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.coral),
            ),
          ),
        ],
      );
    }

    if (order.status == ShopOrderStatus.cancelled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Order Cancelled',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cancel Order', style: AppTextStyles.h4),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You can cancel this order within 2 days of placement if the estimated delivery is more than 5 days away.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Order Age: $orderAge day${orderAge == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall,
              ),
              Text(
                'Days to Delivery: $daysToDelivery day${daysToDelivery == 1 ? '' : 's'}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _cancelOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: _isUpdating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Cancel Order'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _cancelOrder() async {
    setState(() => _isUpdating = true);

    try {
      await _orderService.cancelOrder(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
