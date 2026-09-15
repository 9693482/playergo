import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/count_up_text.dart';
import '../../../../core/widgets/pulse_dot.dart';

/// Sección "Resumen del sistema": frase dinámica basada únicamente en datos
/// reales + tres métricas destacadas con count-up. Sin números inventados.
class HeroSummary extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool animate;

  const HeroSummary({
    super.key,
    required this.stats,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final users = (stats['totalUsers'] as int?) ?? 0;
    final players = (stats['totalPlayers'] as int?) ?? 0;
    final teams = (stats['totalTeams'] as int?) ?? 0;
    final reservations = (stats['totalReservations'] as int?) ?? 0;
    final active = (stats['activeReservations'] as int?) ?? 0;
    final disputes = (stats['openDisputes'] as int?) ?? 0;

    final stats_ = [
      _HeroStat(label: 'USUARIOS', value: users, color: AppColors.info, animate: animate),
      _HeroStat(label: 'JUGADORES', value: players, color: AppColors.primary, animate: animate),
      _HeroStat(label: 'EQUIPOS', value: teams, color: AppColors.warning, animate: animate),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen del sistema',
                      style: AppTypography.subtitle1.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    Text(
                      'Visión general en tiempo real',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulseDot(
                    color: AppColors.success,
                    size: 9,
                    animate: animate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'En vivo',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 520;
              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats_
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: e,
                        ),
                      )
                      .toList(),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: stats_,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Gestionas $reservations reservas, de las cuales $active están activas'
            '${disputes > 0
                ? ' y $disputes disputas requieren atención.'
                : ' y no hay disputas abiertas.'}',
            style: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final bool animate;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          CountUpText(
            value: value,
            animate: animate,
            style: AppTypography.h1.copyWith(
              color: color,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.overline.copyWith(
              color: AppColors.darkTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
