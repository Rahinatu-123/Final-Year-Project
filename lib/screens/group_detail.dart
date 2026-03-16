import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../models/group_order.dart';
import '../services/group_order_service.dart';
import 'group_chat.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;

  const GroupDetailScreen({required this.groupId, super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupOrderService _groupOrderService = GroupOrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, TextEditingController> _priceControllers = {};

  @override
  void dispose() {
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GroupOrder?>(
      future: _groupOrderService.getGroupById(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Group Details'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text('Group not found')),
          );
        }

        final group = snapshot.data!;
        final user = _auth.currentUser;
        final effectiveStatus = group.effectiveStatus;
        final daysLeft = group.deadline.difference(DateTime.now()).inDays;
        final isProfessional = user?.uid == group.professionalId;
        final isCreator = user?.uid == group.createdById;
        final isGroupFull = effectiveStatus == GroupOrderStatus.full;
        final isGroupClosed = effectiveStatus == GroupOrderStatus.closed;
        GroupOrderMember? userMember;
        try {
          userMember = group.members.firstWhere((m) => m.userId == user?.uid);
        } catch (e) {
          userMember = null;
        }

        final canViewFullDetails =
            isCreator || isProfessional || userMember != null;
        final canLeaveGroup =
            userMember != null && !isProfessional && !isCreator && daysLeft > 1;

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
              'Group Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (isCreator)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete group',
                  onPressed: () => _showDeleteConfirmation(group),
                )
              else if (isProfessional)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Chip(
                    label: Text(
                      effectiveStatus.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: effectiveStatus == GroupOrderStatus.open
                        ? AppColors.primary
                        : effectiveStatus == GroupOrderStatus.full
                        ? AppColors.coral
                        : effectiveStatus == GroupOrderStatus.closed
                        ? AppColors.textTertiary
                        : AppColors.success,
                  ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: canViewFullDetails
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGroupHeader(group),
                      const SizedBox(height: 32),
                      if (userMember != null && !isProfessional)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildYourOrderCard(userMember),
                            const SizedBox(height: 16),
                            if (canLeaveGroup)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmLeaveGroup(group),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.coral,
                                    side: const BorderSide(
                                      color: AppColors.coral,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.exit_to_app),
                                  label: const Text(
                                    'Leave Group',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              )
                            else if (!isCreator && daysLeft <= 1)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'You can only leave a group when more than 1 day remains before the join deadline.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      _buildMembersSection(group, isProfessional, user?.uid),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupChatScreen(
                                  groupId: widget.groupId,
                                  groupName: group.name,
                                ),
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
                          icon: const Icon(Icons.message),
                          label: const Text(
                            'Go to Group Chat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : _buildNonMemberPreview(group, isGroupFull, isGroupClosed),
          ),
        );
      },
    );
  }

  Widget _buildNonMemberPreview(
    GroupOrder group,
    bool isGroupFull,
    bool isGroupClosed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.warmGradient,
            borderRadius: BorderRadius.circular(AppBorderRadius.lg),
            boxShadow: AppShadows.colored(AppColors.coral),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Created by ${group.createdByName}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${group.members.length}/${group.maxParticipants} people joined',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (group.description.trim().isNotEmpty) ...[
          const Text(
            'Description',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(group.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
        ],
        if (isGroupClosed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.35),
              ),
            ),
            child: const Text(
              'This group is closed.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (isGroupFull)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.coral.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.coral.withOpacity(0.35)),
            ),
            child: const Text(
              'This group is full. Create a new group.',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _auth.currentUser == null
                  ? null
                  : () => _joinGroup(group),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Join Group',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _joinGroup(GroupOrder group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (group.effectiveStatus == GroupOrderStatus.closed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This group is closed.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    if (group.members.length >= group.maxParticipants) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This group is full. Create a new group.'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    try {
      await _groupOrderService.joinGroup(
        groupId: group.id,
        userId: user.uid,
        userName: user.displayName ?? 'Unknown',
        userImage: user.photoURL ?? '',
        orderDescription: '',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You joined the group successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {});
    } catch (e) {
      final lowerError = e.toString().toLowerCase();
      final message = lowerError.contains('already joined')
          ? 'You can only join this group once.'
          : lowerError.contains('full')
          ? 'This group is full. Create a new group.'
          : 'Failed to join group: $e';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.coral),
      );
    }
  }

  Future<void> _confirmLeaveGroup(GroupOrder group) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _leaveGroup(group);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(GroupOrder group) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final daysLeft = group.deadline.difference(DateTime.now()).inDays;
    if (daysLeft <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only leave a group when more than 1 day remains before the join deadline.',
          ),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    try {
      await _groupOrderService.leaveGroup(groupId: group.id, userId: user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You left the group successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave group: $e'),
          backgroundColor: AppColors.coral,
        ),
      );
    }
  }

  Widget _buildGroupHeader(GroupOrder group) {
    final daysLeft = group.deadline.difference(DateTime.now()).inDays;
    final effectiveStatus = group.effectiveStatus;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        boxShadow: AppShadows.colored(AppColors.coral),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${group.type.toString().split('.').last.toUpperCase()} • Led by ${group.professionalName}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  '${group.members.length}/${group.maxParticipants}',
                  'Members',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStat(
                  '${group.discountPercentage.toStringAsFixed(0)}%',
                  'Discount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHeaderStat(
                  effectiveStatus == GroupOrderStatus.closed
                      ? 'Closed'
                      : '${daysLeft}d',
                  effectiveStatus == GroupOrderStatus.closed
                      ? 'Status'
                      : 'Left',
                ),
              ),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              group.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYourOrderCard(GroupOrderMember member) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        border: Border.all(color: AppColors.success, width: 1.5),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Order',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: member.isPriced ? AppColors.success : AppColors.coral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  member.isPriced ? 'Priced' : 'Awaiting Price',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (member.orderDescription.isNotEmpty) ...[
            Text(member.orderDescription, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 12),
          ],
          if (member.isPriced && member.basePrice != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base Price', style: AppTextStyles.labelSmall),
                    Text(
                      'GH₵${member.basePrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: AppColors.primary),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Your Price (10% off)',
                      style: AppTextStyles.labelSmall,
                    ),
                    Text(
                      'GH₵${member.discountedPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Professional will set your price soon',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.coral,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(
    GroupOrder group,
    bool isProfessional,
    String? userId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Members (${group.members.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (group.members.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: const Center(
              child: Text(
                'No members yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.members.length,
            itemBuilder: (context, index) {
              final member = group.members[index];
              return _buildMemberCard(
                member,
                isProfessional,
                group.id,
                'Member ${index + 1}',
              );
            },
          ),
      ],
    );
  }

  Widget _buildMemberCard(
    GroupOrderMember member,
    bool isProfessional,
    String groupId,
    String displayName,
  ) {
    final isCurrentUser = member.userId == _auth.currentUser?.uid;

    if (!_priceControllers.containsKey(member.userId)) {
      _priceControllers[member.userId] = TextEditingController(
        text: member.basePrice?.toStringAsFixed(2) ?? '',
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member.userImage.isNotEmpty)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(member.userImage),
                  onBackgroundImageError: (_, _) {},
                )
              else
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.surfaceVariant,
                  child: const Icon(Icons.person),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${member.joinedAt.difference(DateTime.now()).inDays < 1 ? 'today' : '${member.joinedAt.difference(DateTime.now()).inDays} days ago'}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              if (member.isPriced)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    border: Border.all(color: AppColors.success),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Priced',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withOpacity(0.1),
                    border: Border.all(color: AppColors.coral),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppColors.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (member.orderDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.orderDescription,
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
          if (isProfessional && !member.isPriced)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceControllers[member.userId],
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Set price (GH₵)',
                          prefixText: 'GH₵ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () =>
                            _setPrice(groupId, member.userId, member.userName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.check),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (member.isPriced && member.basePrice != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Base: GH₵${member.basePrice!.toStringAsFixed(2)}',
                            style: AppTextStyles.labelSmall,
                          ),
                          Text(
                            'Customer pays: GH₵${member.discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      if (isProfessional)
                        TextButton(
                          onPressed: () => _editPrice(
                            groupId,
                            member.userId,
                            member.userName,
                          ),
                          child: const Text('Edit'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _setPrice(
    String groupId,
    String memberId,
    String memberName,
  ) async {
    final priceText = _priceControllers[memberId]?.text ?? '';
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price'),
          backgroundColor: AppColors.coral,
        ),
      );
      return;
    }

    try {
      final basePrice = double.parse(priceText);
      await _groupOrderService.setPriceForMember(
        groupId: groupId,
        memberId: memberId,
        basePrice: basePrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Price set for $memberName'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.coral),
      );
    }
  }

  Future<void> _editPrice(
    String groupId,
    String memberId,
    String memberName,
  ) async {
    final currentPrice = _priceControllers[memberId]?.text ?? '';
    final controller = TextEditingController(text: currentPrice);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Price for $memberName'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: 'Enter new price',
            prefixText: 'GH₵ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                Navigator.pop(context);
                await _setPrice(groupId, memberId, memberName);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(GroupOrder group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _groupOrderService.deleteGroup(group.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Group deleted successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting group: $e'),
                    backgroundColor: AppColors.coral,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
