import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fashionhub/services/inference_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

enum HeightUnit { cm, ftIn }

class DetailsScreen extends StatefulWidget {
  final File frontPhoto;
  final File sidePhoto;

  const DetailsScreen({
    super.key,
    required this.frontPhoto,
    required this.sidePhoto,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _heightController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();
  final _weightController = TextEditingController();
  final _inferenceService = InferenceService();

  String _gender = 'male';
  HeightUnit _heightUnit = HeightUnit.cm;
  bool _isLoading = false;

  @override
  void dispose() {
    _heightController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double? _getHeightInCm() {
    if (_heightUnit == HeightUnit.cm) {
      return double.tryParse(_heightController.text.trim());
    }

    final feet = double.tryParse(_heightFeetController.text.trim());
    final inches = double.tryParse(_heightInchesController.text.trim()) ?? 0;

    if (feet == null || feet <= 0 || inches < 0 || inches >= 12) {
      return null;
    }

    return (feet * 30.48) + (inches * 2.54);
  }

  Future<void> _runInference() async {
    final heightCm = _getHeightInCm();
    final weightKg = double.tryParse(_weightController.text.trim());

    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid height and weight. For feet input, inches must be between 0 and 11.9.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final result = await _inferenceService.predict(
        frontImage: widget.frontPhoto,
        sideImage: widget.sidePhoto,
        gender: _gender,
        heightCm: heightCm,
        weightKg: weightKg,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            result: result,
            gender: _gender,
            heightCm: heightCm,
            weightKg: weightKg,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Prediction failed: $error')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text(
          'Your Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Enter your details to improve prediction accuracy.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'GENDER',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _genderButton('male', 'Male')),
                  const SizedBox(width: 12),
                  Expanded(child: _genderButton('female', 'Female')),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'HEIGHT UNIT',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _heightUnitButton(
                      title: 'CM',
                      selected: _heightUnit == HeightUnit.cm,
                      onTap: () => setState(() => _heightUnit = HeightUnit.cm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _heightUnitButton(
                      title: 'FT / IN',
                      selected: _heightUnit == HeightUnit.ftIn,
                      onTap: () => setState(() => _heightUnit = HeightUnit.ftIn),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_heightUnit == HeightUnit.cm)
                _buildInput(
                  controller: _heightController,
                  label: 'HEIGHT (CM)',
                  hint: 'e.g. 175',
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        controller: _heightFeetController,
                        label: 'HEIGHT (FT)',
                        hint: 'e.g. 5',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        controller: _heightInchesController,
                        label: 'HEIGHT (IN)',
                        hint: 'e.g. 8',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _buildInput(
                controller: _weightController,
                label: 'WEIGHT (KG)',
                hint: 'e.g. 70',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _runInference,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                          ),
                        )
                      : const Text(
                          'Get Measurements',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

  Widget _genderButton(String value, String label) {
    final selected = _gender == value;
    return OutlinedButton(
      onPressed: _isLoading ? null : () => setState(() => _gender = value),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.textPrimary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.textTertiary,
        ),
        backgroundColor: selected
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _heightUnitButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: _isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? AppColors.primary : AppColors.textPrimary,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.textTertiary,
        ),
        backgroundColor: selected
            ? AppColors.primary.withOpacity(0.12)
            : AppColors.surfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          enabled: !_isLoading,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 15,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
