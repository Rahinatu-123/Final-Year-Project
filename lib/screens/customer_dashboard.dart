import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../models/shop_order.dart';
import '../services/shop_order_service.dart';
import 'visualize_style.dart';
import 'sew_with_me.dart';
import 'buy_fabric_with_me.dart';
// AICameraOverlay for measurement capture
import 'indicator.dart'; // MeasurementIndicationScreen for measurement instructions
import 'package:fashionhub/screens/mutual_connections.dart';
import 'shop_order_detail.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late ShopOrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = ShopOrderService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            _buildHeader(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Grid
                  Text("Quick Actions", style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(context),

                  const SizedBox(height: 28),

                  // My Measurements Card
                  Text("My Measurements", style: AppTextStyles.h4),
                  const SizedBox(height: 16),
                  _buildMeasurementCard(),

                  const SizedBox(height: 28),

                  // Recent Orders Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Orders", style: AppTextStyles.h4),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CustomerOrdersListScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "View All",
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<ShopOrder>>(
                    stream: _orderService.getCustomerOrdersStream(
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading orders: ${snapshot.error}',
                          ),
                        );
                      }

                      final orders = snapshot.data ?? [];

                      if (orders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No orders yet. Start shopping!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      // Filter out cancelled orders and show only top 3 on dashboard
                      final activeOrders = orders
                          .where(
                            (order) =>
                                order.status != ShopOrderStatus.cancelled,
                          )
                          .toList();
                      final recentOrders = activeOrders.take(3).toList();

                      if (recentOrders.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.md,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'No active orders',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: List.generate(recentOrders.length, (index) {
                          final order = recentOrders[index];
                          return Column(
                            children: [
                              _buildOrderTile(context, order),
                              if (index < recentOrders.length - 1)
                                const SizedBox(height: 12),
                            ],
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back!",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "My Dashboard",
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildActionCard(
          context,
          "Generate\nMeasurements",
          Icons.straighten,
          AppColors.coral,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeasurementIndicationScreen(),
            ),
          ),
        ),
        _buildActionCard(
          context,
          "My\nChat",
          Icons.search,
          AppColors.accent,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MutualConnectionsPage(),
            ),
          ),
        ),
        _buildActionCard(
          context,
          "Visualize\nStyle",
          Icons.style,
          AppColors.secondary,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VisualizeStylePage()),
          ),
        ),
        _buildActionCard(
          context,
          "Group\nOrder",
          Icons.people,
          AppColors.gold,
          () => _showGroupOrderDialog(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.darkGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Body Measurements",
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.accentLight,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Updated",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _MeasureItem("Bust", "34", "in"),
              _MeasureItem("Waist", "28", "in"),
              _MeasureItem("Hips", "38", "in"),
              _MeasureItem("Length", "42", "in"),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Center(
              child: Text(
                "View All Measurements",
                style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(BuildContext context, ShopOrder order) {
    // Map order status to progress and color
    final statusInfo = _getStatusInfo(order.status);
    final progress = statusInfo['progress'] as double;
    final statusColor = statusInfo['color'] as Color;
    final statusLabel = statusInfo['label'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ShopOrderDetailScreen(orderId: order.id, isForTailor: false),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
              ),
              child: const Icon(Icons.checkroom, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.xs,
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(order.createdAt),
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ShopOrderStatus status) {
    switch (status) {
      case ShopOrderStatus.pending:
        return {'label': 'Pending', 'color': AppColors.gold, 'progress': 0.2};
      case ShopOrderStatus.confirmed:
        return {
          'label': 'Confirmed',
          'color': AppColors.accent,
          'progress': 0.4,
        };
      case ShopOrderStatus.inProgress:
        return {
          'label': 'In Progress',
          'color': AppColors.coral,
          'progress': 0.65,
        };
      case ShopOrderStatus.ready:
        return {
          'label': 'Ready',
          'color': AppColors.accentLight,
          'progress': 0.85,
        };
      case ShopOrderStatus.completed:
        return {
          'label': 'Completed',
          'color': AppColors.success,
          'progress': 1.0,
        };
      case ShopOrderStatus.cancelled:
        return {
          'label': 'Cancelled',
          'color': AppColors.error,
          'progress': 0.0,
        };
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _showGroupOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Order'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SewWithMePage()),
              );
            },
            child: const Text('Sew with me'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BuyFabricWithMePage(),
                ),
              );
            },
            child: const Text('Buy Fabric with me'),
          ),
        ],
      ),
    );
  }
}

class _MeasureItem extends StatelessWidget {
  final String label, value, unit;
  const _MeasureItem(this.label, this.value, this.unit);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                unit,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white60),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white54),
        ),
      ],
    );
  }
}

/// Customer Orders List Screen - Shows all orders
class CustomerOrdersListScreen extends StatefulWidget {
  const CustomerOrdersListScreen({super.key});

  @override
  State<CustomerOrdersListScreen> createState() =>
      _CustomerOrdersListScreenState();
}

class _CustomerOrdersListScreenState extends State<CustomerOrdersListScreen> {
  late ShopOrderService _orderService;

  @override
  void initState() {
    super.initState();
    _orderService = ShopOrderService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<ShopOrder>>(
        stream: _orderService.getCustomerOrdersStream(
          FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading orders', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];
          // Filter out cancelled orders
          final activeOrders = orders
              .where((order) => order.status != ShopOrderStatus.cancelled)
              .toList();

          if (activeOrders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text('No orders yet', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Start shopping to see your orders here',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) {
              final order = activeOrders[index];
              final statusInfo = _getStatusInfo(order.status);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShopOrderDetailScreen(
                        orderId: order.id,
                        isForTailor: false,
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                order.productName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: (statusInfo['color'] as Color)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                  AppBorderRadius.xs,
                                ),
                              ),
                              child: Text(
                                statusInfo['label'] as String,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: statusInfo['color'] as Color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qty: ${order.quantity}',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              'GHS ${order.getTotalPrice().toStringAsFixed(2)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(order.createdAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(ShopOrderStatus status) {
    switch (status) {
      case ShopOrderStatus.pending:
        return {'label': 'Pending', 'color': AppColors.gold};
      case ShopOrderStatus.confirmed:
        return {'label': 'Confirmed', 'color': AppColors.accent};
      case ShopOrderStatus.inProgress:
        return {'label': 'In Progress', 'color': AppColors.coral};
      case ShopOrderStatus.ready:
        return {'label': 'Ready', 'color': AppColors.accentLight};
      case ShopOrderStatus.completed:
        return {'label': 'Completed', 'color': AppColors.success};
      case ShopOrderStatus.cancelled:
        return {'label': 'Cancelled', 'color': AppColors.error};
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  void _showGroupOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Group Order'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SewWithMePage()),
              );
            },
            child: const Text('Sew with me'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Buy Fabric page
              // TODO: Update with actual page route when available
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Buy Fabric feature coming soon')),
              );
            },
            child: const Text('Buy Fabric with me'),
          ),
        ],
      ),
    );
  }
}
