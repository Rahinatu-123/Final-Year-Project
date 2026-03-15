import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fashionhub/services/inference_service.dart';
import 'package:share_plus/share_plus.dart';
import '../services/measurement_service.dart';
import '../theme/app_theme.dart';

enum MeasurementUnit { cm, inch }

class ResultsScreen extends StatefulWidget {
  final MeasurementResult result;
  final String gender;
  final double heightCm;
  final double weightKg;

  const ResultsScreen({
    super.key,
    required this.result,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  MeasurementUnit _measurementUnit = MeasurementUnit.cm;
  final MeasurementService _measurementService = MeasurementService();
  late final Map<String, double> _allMeasurements;

  static const _groups = {
    'Upper Body': [
      'chest',
      'upper-chest',
      'waist',
      'hip',
      'waist-to-hip-distance',
      'neck-circumference',
      'shoulder-breadth',
      'shoulder-length',
      'shoulder-to-crotch',
    ],
    'Arms': [
      'arm-length',
      'sleeve-length',
      'bicep',
      'elbow-circumference',
      'forearm',
      'wrist',
    ],
    'Legs': [
      'leg-length',
      'outseam',
      'inseam',
      'thigh',
      'knee-circumference',
      'calf',
      'ankle',
    ],
    'Height': ['height'],
  };

  static const _higherUncertainty = {'chest', 'waist', 'hip'};

  @override
  void initState() {
    super.initState();
    _allMeasurements = _buildAllMeasurements();
    _saveMeasurementSession();
  }

  double _displayValue(double cmValue) {
    if (_measurementUnit == MeasurementUnit.inch) {
      return cmValue / 2.54;
    }
    return cmValue;
  }

  String _unitLabel() {
    return _measurementUnit == MeasurementUnit.inch ? 'in' : 'cm';
  }

  Map<String, double> _buildAllMeasurements() {
    final measurements = Map<String, double>.from(widget.result.measurements);

    final chest = measurements['chest'];
    final shoulderBreadth = measurements['shoulder-breadth'];
    final armLength = measurements['arm-length'];
    final thigh = measurements['thigh'];
    final bicep = measurements['bicep'];
    final legLength = measurements['leg-length'];
    final height = measurements['height'];

    if (chest != null) {
      measurements['neck-circumference'] = chest / 2.6;
      measurements['upper-chest'] = chest * 0.95;
    }

    if (shoulderBreadth != null) {
      measurements['shoulder-length'] = shoulderBreadth / 2;
    }

    if (armLength != null) {
      measurements['sleeve-length'] = armLength;
    }

    if (thigh != null) {
      measurements['knee-circumference'] = thigh * 0.75;
    }

    if (bicep != null) {
      measurements['elbow-circumference'] = bicep * 0.85;
    }

    if (legLength != null) {
      measurements['inseam'] = legLength * 0.45;
      measurements['outseam'] = legLength;
    }

    if (height != null) {
      measurements['waist-to-hip-distance'] = height * 0.12;
    }

    return measurements;
  }

  Future<void> _saveMeasurementSession() async {
    try {
      await _measurementService.saveMeasurementSession(
        gender: widget.gender,
        heightCm: widget.heightCm,
        weightKg: widget.weightKg,
        measurements: _allMeasurements,
        inferenceMs: widget.result.inferenceTime.inMilliseconds,
      );
    } catch (error) {
      debugPrint('Failed to save measurement session: $error');
    }
  }

  String _buildShareText() {
    return MeasurementService.buildShareText(
      gender: widget.gender,
      heightCm: widget.heightCm,
      weightKg: widget.weightKg,
      measurements: _allMeasurements,
    );
  }

  Future<void> _shareOutsideApp() async {
    await Share.share(_buildShareText());
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _loadShareConnections() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return [];

    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .limit(30)
        .get();

    return usersSnapshot.docs
        .where((doc) => doc.id != currentUser.uid)
        .toList();
  }

  Future<void> _openInstagramStyleShareSheet() async {
    final users = await _loadShareConnections();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Send your measurement summary quickly.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _shareAppIcon(
                      label: 'WhatsApp',
                      icon: Icons.chat,
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _shareOutsideApp();
                      },
                    ),
                    const SizedBox(width: 18),
                    _shareAppIcon(
                      label: 'More',
                      icon: Icons.ios_share,
                      color: AppColors.primary,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await _shareOutsideApp();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your Connections',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No connections found yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                else
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final userDoc = users[index];
                        final data = userDoc.data();
                        final username = (data['username'] ?? 'User')
                            .toString();
                        final shortName = username.length > 10
                            ? '${username.substring(0, 10)}...'
                            : username;

                        return GestureDetector(
                          onTap: () async {
                            Navigator.of(context).pop();
                            await _sendMeasurementToUserChat(
                              otherUserId: userDoc.id,
                              otherUserName: username,
                            );
                          },
                          child: SizedBox(
                            width: 70,
                            child: Column(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary.withOpacity(0.25),
                                        AppColors.primaryDark.withOpacity(0.25),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  shortName,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
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
        );
      },
    );
  }

  Widget _shareAppIcon({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getOrCreateChatId(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Not authenticated');
    }

    final existingChat = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .get();

    for (final doc in existingChat.docs) {
      final participants = doc.data()['participants'] as List<dynamic>? ?? [];
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await FirebaseFirestore.instance.collection('chats').add({
      'participants': [currentUser.uid, otherUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Tap to start chatting',
      'unreadCount': {currentUser.uid: 0, otherUserId: 0},
    });

    return newChat.id;
  }

  Future<void> _sendMeasurementToUserChat({
    required String otherUserId,
    required String otherUserName,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || !mounted) return;

    try {
      final chatId = await _getOrCreateChatId(otherUserId);
      final message = _buildShareText();

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'text': message,
            'senderId': currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
            'type': 'measurement_share',
            'measurementData': _allMeasurements,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: const Text(
          'Your Measurements',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text(
              'Done',
              style: TextStyle(color: AppColors.primary, fontSize: 15),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primaryDark.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SCAN COMPLETE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '25 measurements',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.gender[0].toUpperCase()}${widget.gender.substring(1)} - ${widget.heightCm.toStringAsFixed(0)}cm - ${widget.weightKg.toStringAsFixed(0)}kg',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'UNITS',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ChoiceChip(
                    label: const Text('CM'),
                    selected: _measurementUnit == MeasurementUnit.cm,
                    onSelected: (_) =>
                        setState(() => _measurementUnit = MeasurementUnit.cm),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('INCHES'),
                    selected: _measurementUnit == MeasurementUnit.inch,
                    onSelected: (_) =>
                        setState(() => _measurementUnit = MeasurementUnit.inch),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._groups.entries.map(
                (group) => _buildGroup(group.key, group.value),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chest, waist and hip have higher uncertainty because depth is not visible in 2D photos.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _openInstagramStyleShareSheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceVariant,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: AppColors.textTertiary.withOpacity(0.25),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String title, List<String> cols) {
    final available = cols
        .where((c) => _allMeasurements.containsKey(c))
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: available.asMap().entries.map((entry) {
                final i = entry.key;
                final col = entry.value;
                final val = _allMeasurements[col]!;
                final displayValue = _displayValue(val);
                final isUncertain = _higherUncertainty.contains(col);
                final isLast = i == available.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  _formatName(col),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isUncertain) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13,
                                    color: AppColors.warning.withOpacity(0.7),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${displayValue.toStringAsFixed(1)} ${_unitLabel()}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: AppColors.textTertiary.withOpacity(0.2),
                        indent: 16,
                        endIndent: 16,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatName(String col) {
    return col
        .split('-')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
