import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/fabric_seller_service.dart';
import 'fabric_seller_orders.dart';
import 'my_shop.dart';
import 'my_clients.dart';
import 'mutual_connections.dart';

class FabricSellerDashboard extends StatefulWidget {
  final String sellerId;

  const FabricSellerDashboard({super.key, required this.sellerId});

  @override
  State<FabricSellerDashboard> createState() => _FabricSellerDashboardState();
}

class _FabricSellerDashboardState extends State<FabricSellerDashboard>
    with WidgetsBindingObserver {
  final FabricSellerService _fabricService = FabricSellerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Stream will automatically update when app comes to foreground
      // No need for manual refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _fabricService.streamSalesOverview(widget.sellerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading dashboard: ${snapshot.error}'),
            );
          }

          final salesOverview = snapshot.data ?? {};

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Business',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCards(),
                  const SizedBox(height: 24),
                  // Sales Overview Cards
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildSalesOverviewCards(salesOverview),
                  const SizedBox(height: 24),
                  // Best Selling Fabrics
                  Text(
                    'Best Selling Fabrics',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildBestSellingFabrics(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildManagementCards() {
    return Column(
      children: [
        _buildActionCard(
          title: 'Orders',
          subtitle: 'Track fabric and shop orders',
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFFFEB24C),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FabricSellerOrders(sellerId: widget.sellerId),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'My Shop',
          subtitle: 'Manage products for sale',
          icon: Icons.storefront_rounded,
          color: const Color(0xFFC9184A),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyShopScreen(sellerId: widget.sellerId),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Clients',
          subtitle: 'Keep client profiles and requests',
          icon: Icons.people_rounded,
          color: const Color(0xFF6750A4),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyClientsScreen(
                  tailorId: widget.sellerId,
                  tailorName: 'Fabric Seller',
                  isFabricSeller: true,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          title: 'Chats',
          subtitle: 'Open conversations with your customers',
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF008580),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MutualConnectionsPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.soft,
          border: Border.all(color: color.withOpacity(0.2), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesOverviewCards(Map<String, dynamic> salesOverview) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Sales',
            value: '${salesOverview['totalSales'] ?? 0}',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Revenue',
            value:
                '\$${(salesOverview['totalRevenue'] ?? 0).toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingFabrics() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fabricService.getBestSellingFabrics(widget.sellerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'No sales yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        }

        final fabrics = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fabrics.length,
          itemBuilder: (context, index) {
            final fabric = fabrics[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(fabric['name'] ?? 'Unknown'),
                subtitle: Text('Color: ${fabric['color'] ?? 'N/A'}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${fabric['count']} sales',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${(fabric['revenue'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
