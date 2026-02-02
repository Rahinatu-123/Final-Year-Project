import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class TailorDashboard extends StatelessWidget {
  const TailorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tailorId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Stats Cards
            _buildStatsCards(),

            // Orders Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('measurements_shares')
                    .where('receiverId', isEqualTo: tailorId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var order = snapshot.data!.docs[index];
                      return _buildOrderCard(context, order);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
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
                    "My Workshop",
                    style: AppTextStyles.h2.copyWith(color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textTertiary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Pending",
              "5",
              Icons.pending_actions,
              AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "In Progress",
              "3",
              Icons.autorenew,
              AppColors.coral,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Completed",
              "28",
              Icons.check_circle_outline,
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.xs),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "No orders yet",
            style: AppTextStyles.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            "When clients share their measurements\nwith you, they'll appear here",
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    var measurements = data['measurements'] as Map<String, dynamic>? ?? {};
    String status = data['status'] ?? 'pending';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'in_progress':
        statusColor = AppColors.coral;
        break;
      default:
        statusColor = AppColors.gold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: AppColors.warmGradient,
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.surfaceVariant,
              child: Icon(Icons.person, color: AppColors.textTertiary),
            ),
          ),
          title: Text(
            "New Client Request",
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Container(
            margin: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          children: [
            // Measurements Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _smallMetric("Bust", "${measurements['bust'] ?? '--'}\""),
                  _smallMetric("Waist", "${measurements['waist'] ?? '--'}\""),
                  _smallMetric("Hips", "${measurements['hips'] ?? '--'}\""),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text("View Scan"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.warmGradient,
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      boxShadow: AppShadows.colored(AppColors.coral),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text("Message"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.md,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
