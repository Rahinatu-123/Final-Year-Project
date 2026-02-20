import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import 'order_list.dart';
import 'order_details.dart';
import 'my_shop.dart';
import 'mutual_connections.dart';

class TailorDashboardScreen extends StatefulWidget {
  final String tailorId;

  const TailorDashboardScreen({super.key, required this.tailorId});

  @override
  State<TailorDashboardScreen> createState() => _TailorDashboardScreenState();
}

class _TailorDashboardScreenState extends State<TailorDashboardScreen> {
  late OrderService orderService;

  @override
  void initState() {
    super.initState();
    orderService = OrderService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
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
            // Dashboard Cards (My Clients, My Chat, My Shop)
            _buildDashboardCardsSection(),
            const SizedBox(height: 28),

            // Urgent orders
            _buildUrgentOrdersSection(),
            const SizedBox(height: 28),

            // Recent pending orders
            _buildRecentOrdersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to Your Dashboard',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // My Clients Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderListScreen(tailorId: widget.tailorId),
              ),
            );
          },
          child: _buildDashboardCard(
            title: 'My Clients',
            subtitle: 'View client profiles & requests',
            icon: Icons.people,
            color: const Color(0xFF6750A4),
          ),
        ),
        const SizedBox(height: 12),
        // Orders Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderListScreen(tailorId: widget.tailorId),
              ),
            );
          },
          child: _buildDashboardCard(
            title: 'Orders',
            subtitle: 'Pending & completed orders',
            icon: Icons.list_alt,
            color: const Color(0xFFFEB24C),
          ),
        ),
        const SizedBox(height: 12),
        // My Chat Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MutualConnectionsPage(),
              ),
            );
          },
          child: _buildDashboardCard(
            title: 'My Chat',
            subtitle: 'Messages from clients',
            icon: Icons.chat_bubble,
            color: const Color(0xFF008580),
          ),
        ),
        const SizedBox(height: 12),
        // My Shop Card
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyShopScreen(sellerId: widget.tailorId),
              ),
            );
          },
          child: _buildDashboardCard(
            title: 'My Shop',
            subtitle: 'Manage products for sale',
            icon: Icons.storefront,
            color: const Color(0xFFC9184A),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: color.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Urgent Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderListScreen(tailorId: widget.tailorId),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Order>>(
          future: orderService.getUrgentOrders(widget.tailorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final urgentOrders = snapshot.data ?? [];

            if (urgentOrders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withOpacity(0.05),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No urgent orders. Great work! 🎉',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            return Column(
              children: urgentOrders.take(3).map((order) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBA1A1A).withOpacity(0.05),
                      border: Border.all(
                        color: const Color(0xFFBA1A1A).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.clientName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.style,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A).withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFFBA1A1A).withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${order.daysRemaining()} days',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFBA1A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentOrdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OrderListScreen(tailorId: widget.tailorId),
                  ),
                );
              },
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Order>>(
          future: orderService.getPendingOrdersForTailor(widget.tailorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'No pending orders',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              );
            }

            return Column(
              children: orders.take(5).map((order) {
                final urgencyColor = _getUrgencyColor(order);
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: urgencyColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.clientName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.style,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (order.daysRemaining() / order.daysEstimate)
                                .clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: urgencyColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              urgencyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Color _getUrgencyColor(Order order) {
    switch (order.getTimelineUrgency()) {
      case TimelineUrgency.green:
        return const Color(0xFF2D6A4F);
      case TimelineUrgency.yellow:
        return const Color(0xFFE8A855);
      case TimelineUrgency.red:
        return const Color(0xFFBA1A1A);
    }
  }
}
