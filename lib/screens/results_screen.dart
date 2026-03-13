import 'package:flutter/material.dart';
import 'package:fashionhub/services/inference_service.dart';
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
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
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
                            '${widget.result.measurements.length} measurements',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Inference',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        Text(
                          '${widget.result.inferenceTime.inMilliseconds}ms',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                    onSelected: (_) => setState(() => _measurementUnit = MeasurementUnit.cm),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('INCHES'),
                    selected: _measurementUnit == MeasurementUnit.inch,
                    onSelected: (_) => setState(() => _measurementUnit = MeasurementUnit.inch),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._groups.entries.map((group) => _buildGroup(group.key, group.value)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String title, List<String> cols) {
    final allMeasurements = _buildAllMeasurements();
    final available = cols.where((c) => allMeasurements.containsKey(c)).toList();
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
              border: Border.all(color: AppColors.textTertiary.withOpacity(0.2)),
            ),
            child: Column(
              children: available.asMap().entries.map((entry) {
                final i = entry.key;
                final col = entry.value;
                final val = allMeasurements[col]!;
                final displayValue = _displayValue(val);
                final isUncertain = _higherUncertainty.contains(col);
                final isLast = i == available.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      Divider(height: 1, color: AppColors.textTertiary.withOpacity(0.2), indent: 16, endIndent: 16),
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
