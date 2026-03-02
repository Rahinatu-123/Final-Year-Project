import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/fabric_order.dart';
import '../services/fabric_seller_service.dart';

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
                  // Sales Overview Cards
                  Text(
                    'Sales Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildSalesOverviewCards(salesOverview),
                  const SizedBox(height: 24),
                  // Quick Stats
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildQuickStats(salesOverview),
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

  Widget _buildQuickStats(Map<String, dynamic> salesOverview) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatRow(
              'Average Order Value',
              '\$${(salesOverview['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
            ),
            const Divider(height: 16),
            _buildStatRow(
              'Total Revenue',
              '\$${(salesOverview['totalRevenue'] ?? 0).toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
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
