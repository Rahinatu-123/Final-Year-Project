import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SewWithMePage extends StatefulWidget {
  const SewWithMePage({super.key});

  @override
  State<SewWithMePage> createState() => _SewWithMePageState();
}

class _SewWithMePageState extends State<SewWithMePage> {
  bool _showCreateForm = false;

  final List<Map<String, dynamic>> sampleGroups = [
    {
      'name': 'Bridal Asoebi Group',
      'tailor': 'Royal Stitches',
      'style': 'Lace & Sequins',
      'spots': 7,
      'maxSpots': 10,
      'discount': 15,
      'daysLeft': 3,
      'price': 150.0,
      'image':
          'https://images.pexels.com/photos/984619/pexels-photo-984619.jpeg',
    },
    {
      'name': 'Kente Collection',
      'tailor': 'Adwoa Designs',
      'style': 'Traditional Kente',
      'spots': 4,
      'maxSpots': 8,
      'discount': 10,
      'daysLeft': 7,
      'price': 120.0,
      'image':
          'https://images.pexels.com/photos/1654648/pexels-photo-1654648.jpeg',
    },
    {
      'name': 'Casual Ankara',
      'tailor': 'Fashion Hub',
      'style': 'Ankara Print',
      'spots': 9,
      'maxSpots': 10,
      'discount': 20,
      'daysLeft': 1,
      'price': 80.0,
      'image':
          'https://images.pexels.com/photos/375810/pexels-photo-375810.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sew With Me",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _showCreateForm ? _buildCreatePortal() : _buildMainPortal(),
      floatingActionButton: !_showCreateForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showCreateForm = true),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add),
              label: const Text("Create Group"),
            )
          : null,
    );
  }

  Widget _buildMainPortal() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Browse Groups",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sampleGroups.length,
            itemBuilder: (context, index) {
              return _buildGroupCard(sampleGroups[index]);
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.colored(AppColors.coral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Group Orders, Better Prices",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Join or create group orders with friends and get discounts on custom tailoring.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final progress = (group['spots'] as int) / (group['maxSpots'] as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showGroupDetails(group),
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    group['image'],
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      width: 80,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.checkroom),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${group['tailor']} • ${group['style']}",
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "${group['spots']}/${group['maxSpots']} spots",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${group['discount']}% off",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${group['daysLeft']}d left",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.coral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                        minHeight: 4,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePortal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Create Sew With Me Group",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showCreateForm = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormField("Group Name", "e.g. Bridal Asoebi 2025"),
          const SizedBox(height: 16),
          _buildFormField("Tailor (select or browse)", ""),
          const SizedBox(height: 16),
          _buildFormField("Style (from gallery or upload)", ""),
          const SizedBox(height: 16),
          _buildFormField("Max Participants (2-10)", "10"),
          const SizedBox(height: 16),
          _buildFormField("Discount %", "e.g. 10"),
          const SizedBox(height: 16),
          _buildFormField("Deadline to Join", "Select date"),
          const SizedBox(height: 16),
          _buildFormField("Group Description", "Describe your group..."),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Group created! (Demo)"),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() => _showCreateForm = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Create Group",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _showCreateForm = false),
              child: const Text("Cancel"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showGroupDetails(Map<String, dynamic> group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          group['image'],
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 250,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.checkroom, size: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(group['name'], style: AppTextStyles.h3),
                      const SizedBox(height: 8),
                      Text(
                        "Tailor: ${group['tailor']}",
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildStatChip(
                            "${group['spots']}/${group['maxSpots']}",
                            "Spots",
                          ),
                          const SizedBox(width: 12),
                          _buildStatChip("${group['discount']}%", "Discount"),
                          const SizedBox(width: 12),
                          _buildStatChip("${group['daysLeft']} days", "Left"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Price per person",
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            "GH₵ ${group['price']}",
                            style: AppTextStyles.h4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Joined group! (Demo)"),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Join Group",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}
