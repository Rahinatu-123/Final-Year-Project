import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'order_details.dart';

class OrderListScreen extends StatefulWidget {
  final String tailorId;

  const OrderListScreen({super.key, required this.tailorId});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late OrderService orderService;
  int _selectedTabIndex = 0; // 0: Pending, 1: Completed

  @override
  void initState() {
    super.initState();
    orderService = OrderService();
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
                          'Pending',
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
                          'Completed',
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
                ? _buildPendingOrdersList()
                : _buildCompletedOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersList() {
    return StreamBuilder<List<Order>>(
      stream: orderService.getPendingOrdersStream(widget.tailorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('No pending orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildCompletedOrdersList() {
    return FutureBuilder<List<Order>>(
      future: orderService.getCompletedOrdersForTailor(widget.tailorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text('No completed orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final urgencyColor = _getUrgencyColorFromString(order.getUrgencyColor());
    final daysRemaining = order.daysRemaining();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: order),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Client name and style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.style,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
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
                      order.status.toString().split('.').last.toUpperCase(),
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
              // Timeline bar
              _buildTimelineBar(
                daysRemaining,
                order.daysEstimate,
                urgencyColor,
              ),
              const SizedBox(height: 12),
              // Footer: Days remaining and tags
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    daysRemaining == 0
                        ? 'Completed'
                        : '$daysRemaining days remaining',
                    style: TextStyle(
                      fontSize: 13,
                      color: urgencyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if ((order.tags?.isNotEmpty ?? false))
                    SizedBox(
                      height: 24,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: order.tags!
                            .take(2)
                            .map(
                              (tag) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
}
