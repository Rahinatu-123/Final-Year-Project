import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_order.dart';
import '../models/custom_order.dart';
import '../services/order_service.dart';
import '../services/shop_order_service.dart';
import '../services/custom_order_service.dart';
import '../theme/app_theme.dart';
import 'order_details.dart';
import 'shop_order_detail.dart';
import 'my_clients.dart';

class OrderListScreen extends StatefulWidget {
  final String tailorId;

  const OrderListScreen({super.key, required this.tailorId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late OrderService orderService;
  late ShopOrderService shopOrderService;
  late CustomOrderService customOrderService;
  int _selectedTabIndex = 0; // 0: Custom Orders, 1: Shop Orders

  @override
  void initState() {
    super.initState();
    orderService = OrderService();
    shopOrderService = ShopOrderService();
    customOrderService = CustomOrderService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Column(
                      children: [
                        Text(
                          'Custom Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 0
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedTabIndex == 0)
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Column(
                      children: [
                        Text(
                          'Shop Orders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _selectedTabIndex == 1
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedTabIndex == 1)
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildAllCustomOrdersList()
                : _buildShopOrdersList(),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCustomOrderStatus(CustomOrder order) async {
    final isCurrentlyDelivered = order.status == CustomOrderStatus.delivered;

    try {
      await FirebaseFirestore.instance
          .collection('custom_orders')
          .doc(order.id)
          .update({
            'status': isCurrentlyDelivered ? 'active' : 'delivered',
            'completedAt': isCurrentlyDelivered ? null : Timestamp.now(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCurrentlyDelivered
                ? 'Order moved back to active.'
                : 'Order marked complete.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Widget _buildShopOrdersList() {
    return StreamBuilder<List<ShopOrder>>(
      stream: shopOrderService.getTailorOrdersStream(widget.tailorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('No shop orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildShopOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildShopOrderCard(ShopOrder order) {
    // Determine urgency color based on timeline if available
    Color urgencyColor;
    if (order.estimatedDelivery != null) {
      urgencyColor = _getUrgencyColorFromString(order.getUrgencyColor());
    } else {
      // Fall back to status-based color
      switch (order.status) {
        case ShopOrderStatus.pending:
          urgencyColor = Colors.orange;
          break;
        case ShopOrderStatus.confirmed:
          urgencyColor = Colors.blue;
          break;
        case ShopOrderStatus.inProgress:
          urgencyColor = Colors.purple;
          break;
        case ShopOrderStatus.ready:
          urgencyColor = Colors.green;
          break;
        case ShopOrderStatus.completed:
          urgencyColor = Colors.green;
          break;
        case ShopOrderStatus.cancelled:
          urgencyColor = Colors.red;
          break;
      }
    }

    String statusText;
    switch (order.status) {
      case ShopOrderStatus.pending:
        statusText = 'Pending';
        break;
      case ShopOrderStatus.confirmed:
        statusText = 'Confirmed';
        break;
      case ShopOrderStatus.inProgress:
        statusText = 'In Progress';
        break;
      case ShopOrderStatus.ready:
        statusText = 'Ready';
        break;
      case ShopOrderStatus.completed:
        statusText = 'Completed';
        break;
      case ShopOrderStatus.cancelled:
        statusText = 'Cancelled';
        break;
    }

    final daysRemaining = order.daysRemaining();
    final hasTimeline = order.estimatedDelivery != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShopOrderDetailScreen(orderId: order.id, isForTailor: true),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: urgencyColor.withOpacity(0.2), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Product name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${order.quantity} | GHS ${order.getTotalPrice().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      border: Border.all(color: urgencyColor),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: urgencyColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Timeline bar (if delivery date exists)
              if (hasTimeline)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineBar(
                      daysRemaining,
                      order.estimatedDelivery!
                          .difference(order.createdAt)
                          .inDays,
                      urgencyColor,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          daysRemaining == 0
                              ? 'Due today'
                              : '$daysRemaining days remaining',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: urgencyColor,
                          ),
                        ),
                        Text(
                          'Due: ${order.estimatedDelivery!.toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              // Product image
              if (order.productImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.productImages.first,
                      height: 60,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(height: 60),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCustomOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('custom_orders')
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
                  'No custom orders yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add a client to create an order',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final customOrders = snapshot.data!.docs
            .map(
              (doc) => CustomOrder.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Sort by createdAt descending
        customOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: customOrders.length,
          itemBuilder: (context, index) {
            final order = customOrders[index];
            return _buildCustomOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildCustomOrderCard(CustomOrder order) {
    final urgency = order.getDeliveryUrgency();
    final urgencyColor = _getUrgencyColor(urgency);
    final daysRemaining = order.daysRemaining();
    final progressPercent =
        ((order.daysToDeliver - daysRemaining) / order.daysToDeliver) * 100;
    final isCompleted = order.status == CustomOrderStatus.delivered;

    return GestureDetector(
      onTap: () {
        // Navigate to order details if needed
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
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
                              order.clientName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'GH₵${order.basePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: urgencyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleCustomOrderStatus(order),
                          icon: Icon(
                            isCompleted ? Icons.restore : Icons.check_circle,
                            size: 16,
                          ),
                          label: Text(
                            isCompleted ? 'Mark Active' : 'Mark Complete',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isCompleted
                                ? Colors.orange
                                : AppColors.primary,
                            side: BorderSide(
                              color: isCompleted
                                  ? Colors.orange.withOpacity(0.5)
                                  : AppColors.primary.withOpacity(0.4),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
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
                  _buildCustomOrderTimeline(order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Color _getUrgencyColorFromString(String colorString) {
    switch (colorString) {
      case '#2D6A4F':
        return const Color(0xFF2D6A4F); // Green
      case '#E8A855':
        return const Color(0xFFE8A855); // Yellow/Orange
      case '#BA1A1A':
        return const Color(0xFFBA1A1A); // Red
      default:
        return AppColors.primary;
    }
  }

  Widget _buildCustomOrderTimeline(CustomOrder order) {
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _buildTimelineBar(int daysRemaining, int totalDays, Color color) {
    final percentage = totalDays > 0
        ? (daysRemaining / totalDays).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1 - percentage, // Invert: shows progress from start
            minHeight: 6,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
