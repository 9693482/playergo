import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/rating_service.dart';

class RateScreen extends StatefulWidget {
  final String reservationId;
  final String raterId;
  final String ratedId;
  final String ratedName;

  const RateScreen({
    super.key,
    required this.reservationId,
    required this.raterId,
    required this.ratedId,
    required this.ratedName,
  });

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final _ratingService = RatingService();
  bool _isSubmitting = false;

  int _score = 0;
  int _punctuality = 0;
  int _behavior = 0;
  int _skillLevel = 0;
  int _compliance = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecciona una calificacion general'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _ratingService.submitRating(
        reservationId: widget.reservationId,
        raterId: widget.raterId,
        ratedId: widget.ratedId,
        score: _score,
        punctuality: _punctuality > 0 ? _punctuality : null,
        behavior: _behavior > 0 ? _behavior : null,
        skillLevel: _skillLevel > 0 ? _skillLevel : null,
        compliance: _compliance > 0 ? _compliance : null,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Calificacion enviada'),
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
          'Calificar',
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
            Icon(
              Icons.star_rate_rounded,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Califica a ${widget.ratedName}',
              style: AppTypography.h2.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Calificacion general',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StarRating(
              rating: _score,
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _CategoryRating(
              label: 'Puntualidad',
              rating: _punctuality,
              onChanged: (v) => setState(() => _punctuality = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryRating(
              label: 'Comportamiento',
              rating: _behavior,
              onChanged: (v) => setState(() => _behavior = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryRating(
              label: 'Nivel de juego',
              rating: _skillLevel,
              onChanged: (v) => setState(() => _skillLevel = v),
            ),
            const SizedBox(height: AppSpacing.md),
            _CategoryRating(
              label: 'Cumplimiento',
              rating: _compliance,
              onChanged: (v) => setState(() => _compliance = v),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Comentario (opcional)',
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _commentController,
              maxLines: 3,
              style: AppTypography.body1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cuentanos tu experiencia...',
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
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
                        'Enviar calificacion',
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

class _StarRating extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarRating({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final index = i + 1;
        return IconButton(
          icon: Icon(
            index <= rating ? Icons.star : Icons.star_border,
            color: index <= rating ? AppColors.warning : AppColors.darkTextSecondary,
            size: 36,
          ),
          onPressed: () => onChanged(index),
        );
      }),
    );
  }
}

class _CategoryRating extends StatelessWidget {
  final String label;
  final int rating;
  final ValueChanged<int> onChanged;

  const _CategoryRating({
    required this.label,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: List.generate(5, (i) {
              final index = i + 1;
              return GestureDetector(
                onTap: () => onChanged(index),
                child: Icon(
                  index <= rating ? Icons.star : Icons.star_border,
                  color: index <= rating
                      ? AppColors.warning
                      : AppColors.darkTextSecondary,
                  size: 28,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
