import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

/// A circular position selector pod.
/// Circle + icon + name + semantic color + glow + press interaction.
class PositionPod extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const PositionPod({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<PositionPod> createState() => _PositionPodState();
}

class _PositionPodState extends State<PositionPod> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive || _pressing;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressing = true);
      },
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressing = false);
      },
      child: AnimatedScale(
        scale: _pressing ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          borderColor: isActive ? widget.color.withAlpha(120) : null,
          glow: isActive ? widget.color : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withAlpha(isActive ? 40 : 20),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: widget.color.withAlpha(80),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.label,
                style: AppTypography.caption.copyWith(
                  color: isActive ? widget.color : AppColors.darkTextPrimary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
