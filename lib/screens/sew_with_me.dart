import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/group_order.dart';
import '../services/group_order_service.dart';
import 'group_detail.dart';

class SewWithMePage extends StatefulWidget {
  const SewWithMePage({super.key});

  @override
  State<SewWithMePage> createState() => _SewWithMePageState();
}

class _SewWithMePageState extends State<SewWithMePage> {
  bool _showCreateForm = false;
  final GroupOrderService _groupOrderService = GroupOrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _deadlineController;
  String? _selectedTailorId;
  String? _selectedTailorName;
  String? _selectedTailorImage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _deadlineController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<List<GroupOrder>>(
              stream: _groupOrderService.getAllGroups(GroupOrderType.sewing),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final groups = snapshot.data ?? [];
                final openGroups = groups
                    .where(
                      (g) =>
                          g.status == GroupOrderStatus.open ||
                          g.status == GroupOrderStatus.full,
                    )
                    .toList();

                if (openGroups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No groups available yet. Create one!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: openGroups.length,
                  itemBuilder: (context, index) {
                    return _buildGroupCard(openGroups[index]);
                  },
                );
              },
            ),
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

  Widget _buildGroupCard(GroupOrder group) {
    final progress = group.members.length / group.maxParticipants;
    final daysLeft = group.deadline.difference(DateTime.now()).inDays;

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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupDetailScreen(groupId: group.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    group.image ?? '',
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
                        group.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${group.professionalName}",
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "${group.members.length}/${group.maxParticipants} spots",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${group.discountPercentage.toStringAsFixed(0)}% off",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "${daysLeft}d left",
                            style: AppTextStyles.labelSmall.copyWith(
                              color: daysLeft > 3
                                  ? AppColors.primary
                                  : AppColors.coral,
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
          _buildFormField(
            "Group Name",
            "e.g. Bridal Asoebi 2025",
            _nameController,
          ),
          const SizedBox(height: 16),
          _buildTailorSelector(),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildFormField(
            "Description",
            "Describe your group...",
            _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _createGroup,
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

  Widget _buildTailorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Select Tailor/Professional",
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft,
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              // Filter for tailor and seamstress roles
              final tailors = snapshot.data!.docs.where((doc) {
                final role = (doc['role'] ?? '').toString().toLowerCase();
                return role.contains('tailor') || role.contains('seamstress');
              }).toList();

              return DropdownButtonFormField<String>(
                value: _selectedTailorId,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                hint: const Text("Choose a tailor"),
                items: tailors.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      doc['fullName'] ?? doc['firstName'] ?? 'Unknown',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final tailor = tailors.firstWhere((doc) => doc.id == value);
                    setState(() {
                      _selectedTailorId = value;
                      _selectedTailorName =
                          tailor['fullName'] ??
                          tailor['firstName'] ??
                          'Unknown';
                      _selectedTailorImage = tailor['profileImage'] ?? '';
                    });
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Deadline to Join",
          style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.soft,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) {
                  setState(() {
                    _deadlineController.text =
                        '${picked.day}/${picked.month}/${picked.year}';
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _deadlineController.text.isEmpty
                            ? 'Select deadline'
                            : _deadlineController.text,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
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
            controller: controller,
            maxLines: maxLines,
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

  Future<void> _createGroup() async {
    if (_nameController.text.isEmpty ||
        _selectedTailorId == null ||
        _deadlineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Parse deadline
      final deadlineParts = _deadlineController.text.split('/');
      final deadline = DateTime(
        int.parse(deadlineParts[2]),
        int.parse(deadlineParts[1]),
        int.parse(deadlineParts[0]),
      );

      final group = GroupOrder(
        id: '',
        name: _nameController.text,
        type: GroupOrderType.sewing,
        createdById: user.uid,
        createdByName: user.displayName ?? 'Unknown',
        professionalId: _selectedTailorId!,
        professionalName: _selectedTailorName!,
        professionalImage: _selectedTailorImage ?? '',
        description: _descriptionController.text,
        discountPercentage: 10.0,
        maxParticipants: 10,
        members: [
          GroupOrderMember(
            userId: user.uid,
            userName: user.displayName ?? 'Unknown',
            userImage: user.photoURL ?? '',
            orderDescription: '',
            joinedAt: DateTime.now(),
          ),
        ],
        status: GroupOrderStatus.open,
        createdAt: DateTime.now(),
        deadline: deadline,
        image: null,
      );

      await _groupOrderService.createGroup(group);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Group created successfully!"),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear form
        _nameController.clear();
        _descriptionController.clear();
        _deadlineController.clear();
        _selectedTailorId = null;
        _selectedTailorName = null;
        _selectedTailorImage = null;

        setState(() => _showCreateForm = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating group: $e"),
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
