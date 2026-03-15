import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AllMeasurementsPage extends StatelessWidget {
  const AllMeasurementsPage({super.key, required this.measurements});

  final Map<String, dynamic> measurements;

  String _formatMeasurementName(String key) {
    return key
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final entries = measurements.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'All Measurements',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: entries.isEmpty
          ? Center(
              child: Text(
                'No measurements found.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.textTertiary.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final cm = entry.value is num
                    ? (entry.value as num).toDouble()
                    : double.tryParse(entry.value.toString()) ?? 0;
                final inches = cm / 2.54;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_formatMeasurementName(entry.key)),
                  subtitle: Text(
                    '${cm.toStringAsFixed(1)} cm',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    '${inches.toStringAsFixed(1)} in',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
