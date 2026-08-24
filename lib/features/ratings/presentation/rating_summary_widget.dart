import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/rating_service.dart';

class RatingSummaryWidget extends StatefulWidget {
  final String userId;

  const RatingSummaryWidget({super.key, required this.userId});

  @override
  State<RatingSummaryWidget> createState() => _RatingSummaryWidgetState();
}

class _RatingSummaryWidgetState extends State<RatingSummaryWidget> {
  final _ratingService = RatingService();
  Map<String, dynamic> _stats = {'average': 0.0, 'count': 0};
  List<Rating> _recentRatings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final stats = await _ratingService.getRatingStats(widget.userId);
    final ratings = await _ratingService.getRatingsForUser(widget.userId);
    setState(() {
      _stats = stats;
      _recentRatings = ratings.take(5).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final avg = (_stats['average'] as double);
    final count = _stats['count'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: AppRadius.medium,
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < avg.round() ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 18,
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$count calificaciones',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  children: [
                    _StatBar(label: 'Puntualidad', value: _stats['punctuality'] as double),
                    _StatBar(label: 'Comportamiento', value: _stats['behavior'] as double),
                    _StatBar(label: 'Nivel', value: _stats['skillLevel'] as double),
                    _StatBar(label: 'Cumplimiento', value: _stats['compliance'] as double),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_recentRatings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Comentarios recientes',
            style: AppTypography.subtitle1.copyWith(
              color: AppColors.darkTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._recentRatings.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (r.raterName ?? 'U')[0].toUpperCase(),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          r.raterName ?? 'Anonimo',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.darkTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < r.score ? Icons.star : Icons.star_border,
                            color: AppColors.warning,
                            size: 14,
                          );
                        }),
                      ),
                    ],
                  ),
                  if (r.comment != null && r.comment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      r.comment!,
                      style: AppTypography.body2.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatBar extends StatelessWidget {
  final String label;
  final double value;

  const _StatBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 5,
              backgroundColor: AppColors.darkSurfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 24,
            child: Text(
              value.toStringAsFixed(1),
              style: AppTypography.caption.copyWith(
                color: AppColors.darkTextPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
