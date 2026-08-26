import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';
import 'progress_ring.dart';
import 'count_up_text.dart';
import 'pulse_dot.dart';

/// Circular KPI card for the SPORT CONTROL CENTER aesthetic.
/// Composes: ProgressRing + icon + number (count-up) + label + status.
class CircularKPI extends StatefulWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  final double ringProgress;
  final String statusLabel;
  final bool animate;

  const CircularKPI({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.ringProgress = 0.0,
    this.statusLabel = '',
    this.animate = true,
  });

  @override
  State<CircularKPI> createState() => _CircularKPIState();
}

class _CircularKPIState extends State<CircularKPI> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ring = ProgressRing(
      size: 100,
      strokeWidth: 8,
      progress: widget.ringProgress,
      color: widget.color,
      animate: widget.animate,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const SizedBox(height: 2),
          CountUpText(
            value: widget.value,
            animate: widget.animate,
            style: AppTypography.h3.copyWith(
              color: AppColors.darkTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final labelText = Text(
      widget.label.toUpperCase(),
      style: AppTypography.overline.copyWith(
        color: AppColors.darkTextSecondary,
        letterSpacing: 1.2,
      ),
      textAlign: TextAlign.center,
    );

    final statusRow = widget.statusLabel.isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseDot(color: widget.color, size: 6, animate: widget.animate),
              const SizedBox(width: 4),
              Text(
                widget.statusLabel,
                style: AppTypography.caption.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          )
        : const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 220),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          borderColor: _hover ? widget.color : null,
          glow: _hover ? widget.color : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ring,
              const SizedBox(height: AppSpacing.sm),
              labelText,
              if (widget.statusLabel.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                statusRow,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
