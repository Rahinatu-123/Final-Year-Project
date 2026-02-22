import 'package:flutter/material.dart';
import '../models/custom_order.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  final String tailorId;
  final String clientId;
  final String clientName;

  const OrdersScreen({
    Key? key,
    required this.tailorId,
    required this.clientId,
    required this.clientName,
  }) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.clientName} - Orders'),
        backgroundColor: AppColors.primary,
        elevation: 1,
        foregroundColor: Colors.white,
      ),
      body: Center(child: Text('Orders for ${widget.clientName}')),
    );
  }
}

class OrderDetailCard extends StatelessWidget {
  final CustomOrder order;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const OrderDetailCard({
    Key? key,
    required this.order,
    required this.onTap,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final urgency = order.getDeliveryUrgency();
    final urgencyColor = _getUrgencyColor(urgency);
    final daysRemaining = order.daysRemaining();
    final progressPercent =
        ((order.daysToDeliver - daysRemaining) / order.daysToDeliver) * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border.all(color: urgencyColor.withOpacity(0.2)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
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
                              order.measurements,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'GH₵${order.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: urgencyColor,
                            ),
                          ),
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: onDelete,
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 18),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                            child: const Icon(Icons.more_vert, size: 18),
                          ),
                        ],
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
}
