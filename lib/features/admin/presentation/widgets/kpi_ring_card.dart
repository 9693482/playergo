import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/count_up_text.dart';
import '../../../../core/widgets/pulse_dot.dart';

/// KPI circular del "Sport Control Center".
///
/// Composición: anillo animado + icono central + número (count-up) + etiqueta
/// + indicador de estado. En modo [wide] el anillo queda a la izquierda y el
/// texto a la derecha (tarjeta destacada). Hover: escala + glow + borde de
/// color (transición ~220ms). El [ringProgress] es decorativo (no inventa %).
class KpiRingCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final double ringProgress;
  final String statusLabel;
  final bool wide;
  final bool animate;

  const KpiRingCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.ringProgress,
    required this.statusLabel,
    this.wide = false,
    this.animate = true,
  });

  @override
  State<KpiRingCard> createState() => _KpiRingCardState();
}

class _KpiRingCardState extends State<KpiRingCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ring = ProgressRing(
      size: 132,
      strokeWidth: 11,
      progress: widget.ringProgress,
      color: widget.color,
      animate: widget.animate,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: widget.wide ? 28 : 26),
          const SizedBox(height: 4),
          CountUpText(
            value: widget.value,
            animate: widget.animate,
            style: AppTypography.h2.copyWith(
              color: AppColors.darkTextPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final statusRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseDot(color: widget.color, size: 8, animate: widget.animate),
        const SizedBox(width: 6),
        Text(
          widget.statusLabel,
          style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
        ),
      ],
    );

    final labelText = Text(
      widget.label.toUpperCase(),
      style: AppTypography.overline.copyWith(
        color: AppColors.darkTextSecondary,
        letterSpacing: 1.5,
      ),
    );

    final inner = widget.wide
        ? Row(
            children: [
              ring,
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [labelText, const SizedBox(height: 6), statusRow],
                ),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ring,
              const SizedBox(height: AppSpacing.md),
              labelText,
              const SizedBox(height: AppSpacing.sm),
              statusRow,
            ],
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: _hover && widget.animate
            ? Matrix4.diagonal3Values(1.04, 1.04, 1.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: GlassCard(
          padding: widget.wide
              ? const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg, horizontal: AppSpacing.xl)
              : const EdgeInsets.symmetric(
                  vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
          borderColor: _hover ? widget.color : null,
          glow: _hover ? widget.color : null,
          child: Semantics(
            label: '${widget.label}: ${widget.value}',
            child: inner,
          ),
        ),
      ),
    );
  }
}
