import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'glass_card.dart';

/// Circular quick action button: icon circle + label.
/// Used for QR, Reservas, etc.
class QuickActionCircular extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCircular({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  State<QuickActionCircular> createState() => _QuickActionCircularState();
}

class _QuickActionCircularState extends State<QuickActionCircular> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: GlassCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.lg,
                  horizontal: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withAlpha(25),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withAlpha(40),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(widget.icon, color: widget.color, size: 22),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.darkTextPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
