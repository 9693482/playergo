import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/dispute_service.dart';

class OpenDisputeScreen extends StatefulWidget {
  final String reservationId;
  final String userId;

  const OpenDisputeScreen({
    super.key,
    required this.reservationId,
    required this.userId,
  });

  @override
  State<OpenDisputeScreen> createState() => _OpenDisputeScreenState();
}

class _OpenDisputeScreenState extends State<OpenDisputeScreen> {
  final _disputeService = DisputeService();
  final _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitDispute() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona un motivo'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _disputeService.openDispute(
        reservationId: widget.reservationId,
        openedBy: widget.userId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Disputa abierta exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Abrir Disputa',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(25),
                borderRadius: AppRadius.medium,
                border: Border.all(
                  color: AppColors.warning.withAlpha(80),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Las disputas son revisadas por el equipo de soporte. Proporciona la mayor informacion posible.',
                      style: TextStyle(color: AppColors.warning, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Motivo de la disputa',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...DisputeService.disputeReasons.map(
              (reason) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _selectedReason == reason
                      ? AppColors.primary.withAlpha(30)
                      : AppColors.darkSurface,
                  borderRadius: AppRadius.medium,
                  border: Border.all(
                    color: _selectedReason == reason
                        ? AppColors.primary
                        : AppColors.darkSurfaceVariant,
                    width: 1.5,
                  ),
                ),
                child: RadioListTile<String>(
                  title: Text(
                    reason,
                    style: AppTypography.body1.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (v) => setState(() => _selectedReason = v),
                  activeColor: AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Descripcion (opcional)',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              style: AppTypography.body1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Describe los detalles del problema...',
                hintStyle: AppTypography.body2.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
                filled: true,
                fillColor: AppColors.darkSurfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDispute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Enviar disputa',
                        style: AppTypography.button,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
