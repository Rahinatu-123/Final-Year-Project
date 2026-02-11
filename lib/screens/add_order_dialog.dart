import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';

class AddOrderDialog extends StatefulWidget {
  final String tailorId;
  final String clientId;
  final String clientName;

  const AddOrderDialog({
    super.key,
    required this.tailorId,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<AddOrderDialog> createState() => _AddOrderDialogState();
}

class _AddOrderDialogState extends State<AddOrderDialog> {
  late OrderService orderService;
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _measurementsController = TextEditingController();
  final TextEditingController _daysEstimateController = TextEditingController(
    text: '7',
  );
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<OrderVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    orderService = OrderService();
  }

  @override
  void dispose() {
    _styleController.dispose();
    _measurementsController.dispose();
    _daysEstimateController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Client name (auto-populated)
              _buildTextField(
                label: 'Client Name',
                controller: TextEditingController(text: widget.clientName),
                enabled: false,
              ),
              const SizedBox(height: 16),

              // Style dropdown
              _buildTextField(
                label: 'Style/Type of Clothing',
                controller: _styleController,
                hintText: 'e.g., Dress, Suit, Shirt, Blouse',
              ),
              const SizedBox(height: 16),

              // Measurements
              _buildTextField(
                label: 'Measurements',
                controller: _measurementsController,
                hintText: 'e.g., Chest: 36", Waist: 28"...',
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Days estimate
              _buildTextField(
                label: 'Days Estimate',
                controller: _daysEstimateController,
                hintText: 'Number of days to complete',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Variants section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Color & Size Variants',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            label: 'Color',
                            controller: _colorController,
                            hintText: 'e.g., Red',
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            label: 'Size',
                            controller: _sizeController,
                            hintText: 'e.g., S, M, L',
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      label: 'Notes (Optional)',
                      controller: _notesController,
                      hintText: 'Any special notes for this variant',
                      compact: true,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addVariant,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (_variants.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._variants.asMap().entries.map((entry) {
                        int index = entry.key;
                        OrderVariant variant = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(6),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Size: ${variant.size}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18),
                                onPressed: () {
                                  setState(() => _variants.removeAt(index));
                                },
                                padding: const EdgeInsets.all(0),
                                constraints: const BoxConstraints(
                                  maxHeight: 24,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: _isLoading ? null : _createOrder,
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Create Order',
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
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: compact ? label : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  void _addVariant() {
    if (_colorController.text.isEmpty || _sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in color and size'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _variants.add(
        OrderVariant(
          color: _colorController.text,
          size: _sizeController.text,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        ),
      );
      _colorController.clear();
      _sizeController.clear();
      _notesController.clear();
    });
  }

  Future<void> _createOrder() async {
    // Validation
    if (_styleController.text.isEmpty ||
        _measurementsController.text.isEmpty ||
        _daysEstimateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one variant'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newOrder = Order(
        id: '', // Firestore will generate this
        tailorId: widget.tailorId,
        clientId: widget.clientId,
        clientName: widget.clientName,
        style: _styleController.text,
        measurements: _measurementsController.text,
        variants: _variants,
        daysEstimate: int.parse(_daysEstimateController.text),
        createdAt: DateTime.now(),
        status: OrderStatus.pending,
      );

      final orderId = await orderService.createOrder(newOrder);

      if (mounted) {
        Navigator.pop(context, orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order created successfully'),
            backgroundColor: Color(0xFF2D6A4F),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
