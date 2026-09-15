import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/skeleton.dart';

/// Skeleton loaders coherentes con el nuevo diseño "Sport Control Center":
/// círculos pulsantes + líneas de texto. No muestra valores falsos.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Skeleton(width: 200, height: 18),
                  Spacer(),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Skeleton(width: 90, height: 30),
                  Skeleton(width: 90, height: 30),
                  Skeleton(width: 90, height: 30),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const Skeleton(height: 14, width: 280),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: List.generate(
            6,
            (_) => SizedBox(
              width: 160,
              child: GlassCard(
                child: Column(
                  children: const [
                    Skeleton(width: 110, height: 110, borderRadius: 55),
                    SizedBox(height: AppSpacing.md),
                    Skeleton(height: 12, width: 80),
                    SizedBox(height: AppSpacing.sm),
                    Skeleton(height: 10, width: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: GlassCard(
              child: Row(
                children: [
                  Skeleton(width: 44, height: 44, borderRadius: 22),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(height: 14, width: 160),
                        SizedBox(height: AppSpacing.sm),
                        Skeleton(height: 12, width: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
