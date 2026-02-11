import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderService orderService;
  late Order currentOrder;
  bool _isEditing = false;
  bool _isLoading = false;

  // Edit controllers
  late TextEditingController _measurementsController;
  late TextEditingController _notesController;
  late TextEditingController _daysEstimateController;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
    orderService = OrderService();
    _measurementsController = TextEditingController(
      text: currentOrder.measurements,
    );
    _notesController = TextEditingController(
      text: currentOrder.additionalNotes ?? '',
    );
    _daysEstimateController = TextEditingController(
      text: currentOrder.daysEstimate.toString(),
    );
  }

  @override
  void dispose() {
    _measurementsController.dispose();
    _notesController.dispose();
    _daysEstimateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    final daysRemaining = currentOrder.daysRemaining();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: AppColors.textPrimary,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with client and style info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.05),
                border: Border.all(color: urgencyColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client: ${currentOrder.clientName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Style: ${currentOrder.style}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Timeline section
            _buildTimelineSection(urgencyColor, daysRemaining),
            const SizedBox(height: 24),

            // Measurements section
            _buildSection(
              'Measurements',
              _isEditing
                  ? TextField(
                      controller: _measurementsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter measurements',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : Text(
                      currentOrder.measurements,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Variants section
            if (currentOrder.variants.isNotEmpty) ...[
              _buildVariantsSection(),
              const SizedBox(height: 20),
            ],

            // Additional notes section
            _buildSection(
              'Additional Notes',
              _isEditing
                  ? TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add notes or custom measurements',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : Text(
                      currentOrder.additionalNotes ?? 'No notes added',
                      style: TextStyle(
                        fontSize: 14,
                        color: currentOrder.additionalNotes != null
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // Tags section
            if (currentOrder.tags?.isNotEmpty ?? false) ...[
              _buildTagsSection(),
              const SizedBox(height: 20),
            ],

            // Days estimate section
            _buildSection(
              'Days Estimate',
              _isEditing
                  ? TextField(
                      controller: _daysEstimateController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Number of days',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : Text(
                      '${currentOrder.daysEstimate} days',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Status toggle section
            if (!_isEditing) _buildStatusToggleSection(urgencyColor),

            // Edit buttons
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
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
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white),
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

  Widget _buildTimelineSection(Color urgencyColor, int daysRemaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.surfaceVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Timeline Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  border: Border.all(color: urgencyColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysRemaining == 0 ? 'Completed' : '$daysRemaining days left',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (currentOrder.daysRemaining() / currentOrder.daysEstimate)
                  .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: urgencyColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Variants',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: currentOrder.variants.length,
          itemBuilder: (context, index) {
            final variant = currentOrder.variants[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.color,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Size: ${variant.size}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (variant.notes != null)
                    Text(
                      variant.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentOrder.tags!
              .map(
                (tag) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatusToggleSection(Color urgencyColor) {
    return Column(
      children: [
        if (currentOrder.status == OrderStatus.pending)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _markAsCompleted,
              style: ElevatedButton.styleFrom(
                backgroundColor: urgencyColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Mark as Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _revertToPending,
              style: OutlinedButton.styleFrom(
                foregroundColor: urgencyColor,
                side: BorderSide(color: urgencyColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Revert to Pending',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Color _getUrgencyColor() {
    switch (currentOrder.getTimelineUrgency()) {
      case TimelineUrgency.green:
        return const Color(0xFF2D6A4F);
      case TimelineUrgency.yellow:
        return const Color(0xFFE8A855);
      case TimelineUrgency.red:
        return const Color(0xFFBA1A1A);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final updatedOrder = currentOrder.copyWith(
        measurements: _measurementsController.text,
        additionalNotes: _notesController.text,
        daysEstimate:
            int.tryParse(_daysEstimateController.text) ??
            currentOrder.daysEstimate,
      );

      await orderService.updateOrder(updatedOrder);
      setState(() {
        currentOrder = updatedOrder;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order updated successfully'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsCompleted() async {
    setState(() => _isLoading = true);

    try {
      await orderService.completeOrder(currentOrder.id);
      setState(() {
        currentOrder = currentOrder.copyWith(
          status: OrderStatus.completed,
          completedAt: DateTime.now(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as completed'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _revertToPending() async {
    setState(() => _isLoading = true);

    try {
      await orderService.revertOrderToPending(currentOrder.id);
      setState(() {
        currentOrder = currentOrder.copyWith(
          status: OrderStatus.pending,
          completedAt: null,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order reverted to pending'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
