import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../models/shop_order.dart';
import '../services/shop_order_service.dart';
import '../services/measurement_service.dart';
import 'visualize_style.dart';
import 'sew_with_me.dart';
import 'buy_fabric_with_me.dart';
// AICameraOverlay for measurement capture
import 'indicator.dart'; // MeasurementIndicationScreen for measurement instructions
import 'all_measurements_page.dart';
import 'package:fashionhub/screens/mutual_connections.dart';
import 'shop_order_detail.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  late ShopOrderService _orderService;
  final MeasurementService _measurementService = MeasurementService();

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
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _measurementService.watchLatestMeasurement(),
      builder: (context, snapshot) {
        final latest = snapshot.data;
        final measurementsRaw =
            latest?['measurements'] as Map<String, dynamic>?;
        final measurements = measurementsRaw == null
            ? <String, dynamic>{}
            : Map<String, dynamic>.from(measurementsRaw);

        final bust = _formatInches(measurements['chest']);
        final waist = _formatInches(measurements['waist']);
        final hips = _formatInches(measurements['hip']);
        final length = _formatInches(
          measurements['outseam'] ??
              measurements['leg-length'] ??
              measurements['inseam'],
        );

        final hasMeasurement = measurements.isNotEmpty;

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
                    'Body Measurements',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: hasMeasurement
                          ? AppColors.success.withOpacity(0.2)
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppBorderRadius.xl),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasMeasurement
                              ? Icons.check_circle
                              : Icons.info_outline,
                          color: hasMeasurement
                              ? AppColors.accentLight
                              : Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasMeasurement ? 'Updated' : 'No data',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: hasMeasurement
                                ? AppColors.accentLight
                                : Colors.white70,
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
                children: [
                  _MeasureItem('Bust', bust, 'in'),
                  _MeasureItem('Waist', waist, 'in'),
                  _MeasureItem('Hips', hips, 'in'),
                  _MeasureItem('Length', length, 'in'),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: hasMeasurement
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AllMeasurementsPage(measurements: measurements),
                        ),
                      )
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MeasurementIndicationScreen(),
                        ),
                      ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      hasMeasurement
                          ? 'View All Measurements'
                          : 'Generate Measurements',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (hasMeasurement) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openShareOptions(
                      latest: latest,
                      measurements: measurements,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.45)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Measurements'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareLatestMeasurements({
    required Map<String, dynamic>? latest,
    required Map<String, dynamic> measurements,
  }) async {
    if (measurements.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No measurements available to share.')),
      );
      return;
    }

    final typedMeasurements = measurements.map((key, value) {
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value.toString()) ?? 0.0;
      return MapEntry(key, parsed);
    });

    final gender = (latest?['gender'] ?? 'unknown').toString();
    final heightCm = (latest?['heightCm'] as num?)?.toDouble() ?? 0;
    final weightKg = (latest?['weightKg'] as num?)?.toDouble() ?? 0;

    final shareText = MeasurementService.buildShareText(
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      measurements: typedMeasurements,
    );

    await Share.share(shareText);
  }

  Future<void> _openShareOptions({
    required Map<String, dynamic>? latest,
    required Map<String, dynamic> measurements,
  }) async {
    if (measurements.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No measurements available to share.')),
      );
      return;
    }

    final typedMeasurements = measurements.map((key, value) {
      final parsed = value is num
          ? value.toDouble()
          : double.tryParse(value.toString()) ?? 0.0;
      return MapEntry(key, parsed);
    });

    final gender = (latest?['gender'] ?? 'unknown').toString();
    final heightCm = (latest?['heightCm'] as num?)?.toDouble() ?? 0;
    final weightKg = (latest?['weightKg'] as num?)?.toDouble() ?? 0;

    final recipients = await _loadChatRecipients();
    if (!mounted) return;

    MeasurementShareUnit selectedUnit = MeasurementShareUnit.both;

    String shareTextFor(MeasurementShareUnit unit) {
      return MeasurementService.buildShareText(
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
        measurements: typedMeasurements,
        unit: unit,
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share Measurements', style: AppTextStyles.h4),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('CM'),
                        selected: selectedUnit == MeasurementShareUnit.cm,
                        onSelected: (_) => setModalState(() {
                          selectedUnit = MeasurementShareUnit.cm;
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('INCH'),
                        selected: selectedUnit == MeasurementShareUnit.inch,
                        onSelected: (_) => setModalState(() {
                          selectedUnit = MeasurementShareUnit.inch;
                        }),
                      ),
                      ChoiceChip(
                        label: const Text('BOTH'),
                        selected: selectedUnit == MeasurementShareUnit.both,
                        onSelected: (_) => setModalState(() {
                          selectedUnit = MeasurementShareUnit.both;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await Share.share(shareTextFor(selectedUnit));
                          },
                          child: SizedBox(
                            width: 78,
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.ios_share,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Outside',
                                  style: AppTextStyles.labelSmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your Chat Contacts',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recipients.isEmpty)
                    Text(
                      'No existing chats yet. Start a chat first, then share here.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    SizedBox(
                      height: 94,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: recipients.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final recipient = recipients[index];
                          final username = recipient['username'] ?? 'User';
                          final shortName = username.length > 10
                              ? '${username.substring(0, 10)}...'
                              : username;

                          return GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              await _sendMeasurementToChat(
                                chatId: recipient['chatId']!,
                                otherUserId: recipient['userId']!,
                                otherUserName: username,
                                shareText: shareTextFor(selectedUnit),
                                typedMeasurements: typedMeasurements,
                              );
                            },
                            child: SizedBox(
                              width: 74,
                              child: Column(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    shortName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, String>>> _loadChatRecipients() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final chatsSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    final recipients = <Map<String, String>>[];
    final seenUserIds = <String>{};

    for (final chatDoc in chatsSnapshot.docs) {
      final chatData = chatDoc.data();
      final participants = (chatData['participants'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      String? otherUserId;
      for (final participantId in participants) {
        if (participantId != currentUser.uid) {
          otherUserId = participantId;
          break;
        }
      }

      if (otherUserId == null || seenUserIds.contains(otherUserId)) {
        continue;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();
      final userData = userDoc.data();
      final username = (userData?['username'] ?? userData?['name'] ?? 'User')
          .toString();

      recipients.add({
        'chatId': chatDoc.id,
        'userId': otherUserId,
        'username': username,
      });
      seenUserIds.add(otherUserId);
    }

    return recipients;
  }

  Future<void> _sendMeasurementToChat({
    required String chatId,
    required String otherUserId,
    required String otherUserName,
    required String shareText,
    required Map<String, double> typedMeasurements,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'text': shareText,
            'senderId': currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'measurement_share',
            'measurementData': typedMeasurements,
          });

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'lastMessage': 'Shared body measurements',
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([currentUser.uid, otherUserId]),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Measurements shared with $otherUserName')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share in chat: $error')),
      );
    }
  }

  String _formatInches(dynamic value) {
    if (value == null) return '--';
    final cm = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (cm == null) return '--';
    return (cm / 2.54).toStringAsFixed(1);
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
