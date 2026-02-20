import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fabric_order.dart';
import '../services/fabric_seller_service.dart';

class FabricSellerOrders extends StatefulWidget {
  final String sellerId;

  const FabricSellerOrders({super.key, required this.sellerId});

  @override
  State<FabricSellerOrders> createState() => _FabricSellerOrdersState();
}

class _FabricSellerOrdersState extends State<FabricSellerOrders> {
  final FabricSellerService _fabricService = FabricSellerService();
  FabricOrderStatus? _selectedStatus;
  bool _isLoading = true;
  late List<FabricOrder> _allOrders;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _fabricService.getSellerOrders(widget.sellerId);
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading orders: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _selectedStatus == null
        ? _allOrders
        : _allOrders.where((order) => order.status == _selectedStatus).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status Filter
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Orders'),
                          selected: _selectedStatus == null,
                          onSelected: (selected) {
                            setState(() => _selectedStatus = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...FabricOrderStatus.values.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(_getStatusLabel(status)),
                              selected: _selectedStatus == status,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStatus = selected ? status : null;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                // Orders List
                Expanded(
                  child: filteredOrders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(filteredOrders[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No orders', style: Theme.of(context).textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _buildOrderCard(FabricOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Order Header with Urgency Indicator
          Container(
            decoration: BoxDecoration(
              color: _getUrgencyColor(order).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Client: ${order.clientName}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(order),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.getStatusString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Order Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items Summary
                Text(
                  '${order.items.length} item(s) - Total: GHS ${order.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Items List
                ...order.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.fabricName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${item.quantityYards} yards - ${item.color}',
                              style: const TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                        Text(
                          '\$${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 16),
                // Order Meta Information
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery: ${order.deliveryMethod}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          'Status: ${order.paymentStatus}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Est. ${order.estimatedDays ?? 0} days',
                          style: const TextStyle(fontSize: 11),
                        ),
                        Text(
                          _getTimeAgo(order.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showOrderDetailsDialog(order);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(FabricOrder order) {
    switch (order.getUrgency()) {
      case OrderUrgency.green:
        return Colors.green;
      case OrderUrgency.yellow:
        return Colors.orange;
      case OrderUrgency.red:
        return Colors.red;
    }
  }

  String _getStatusLabel(FabricOrderStatus status) {
    switch (status) {
      case FabricOrderStatus.pending:
        return 'Pending';
      case FabricOrderStatus.processing:
        return 'Processing';
      case FabricOrderStatus.readyForPickup:
        return 'Ready';
      case FabricOrderStatus.delivered:
        return 'Delivered';
      case FabricOrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'just now';
  }

  void _showOrderDetailsDialog(FabricOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return FabricOrderDetailsSheet(
          order: order,
          fabricService: _fabricService,
          onStatusUpdate: _loadOrders,
        );
      },
    );
  }
}

class FabricOrderDetailsSheet extends StatefulWidget {
  final FabricOrder order;
  final FabricSellerService fabricService;
  final Function() onStatusUpdate;

  const FabricOrderDetailsSheet({
    super.key,
    required this.order,
    required this.fabricService,
    required this.onStatusUpdate,
  });

  @override
  State<FabricOrderDetailsSheet> createState() =>
      _FabricOrderDetailsSheetState();
}

class _FabricOrderDetailsSheetState extends State<FabricOrderDetailsSheet> {
  late FabricOrderStatus _newStatus;
  final TextEditingController _noteController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _newStatus = widget.order.status;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                // Customer Info
                _buildSection('Customer Information', [
                  _buildInfoRow('Name', widget.order.clientName),
                  _buildInfoRow('Email', widget.order.clientEmail),
                  _buildInfoRow('Phone', widget.order.clientPhone),
                ]),
                const SizedBox(height: 16),
                // Order Items
                _buildSection('Order Items', [
                  ...widget.order.items.map((item) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fabricName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${item.quantityYards} yards x GHS ${item.pricePerYard.toStringAsFixed(2)} = GHS ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ]),
                const SizedBox(height: 16),
                // Delivery Info
                _buildSection('Delivery Information', [
                  _buildInfoRow('Method', widget.order.deliveryMethod),
                  if (widget.order.deliveryAddress != null)
                    _buildInfoRow('Address', widget.order.deliveryAddress!),
                  if (widget.order.pickupLocation != null)
                    _buildInfoRow('Pickup', widget.order.pickupLocation!),
                  _buildInfoRow(
                    'Est. Days',
                    '${widget.order.estimatedDays ?? 0} days',
                  ),
                ]),
                const SizedBox(height: 16),
                // Update Status
                _buildSection('Update Status', [
                  DropdownButton<FabricOrderStatus>(
                    value: _newStatus,
                    isExpanded: true,
                    onChanged: (status) {
                      setState(() => _newStatus = status!);
                    },
                    items: FabricOrderStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                  ),
                ]),
                const SizedBox(height: 16),
                // Add Note
                Text(
                  'Add Note',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add special instructions or updates...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _updateOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Order'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrder() async {
    setState(() => _isUpdating = true);
    try {
      await widget.fabricService.updateOrderStatus(widget.order.id, _newStatus);

      if (_noteController.text.isNotEmpty) {
        await widget.fabricService.addOrderNote(
          widget.order.id,
          _noteController.text,
        );
      }

      widget.onStatusUpdate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating order: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
