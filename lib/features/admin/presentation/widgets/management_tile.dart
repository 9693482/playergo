import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

/// Tarjeta horizontal de la sección "Gestión".
///
/// Icono dentro de círculo + título + descripción + flecha. Hover: eleva
/// ligeramente, revela línea de acento y glow. Conserva el [onTap] original
/// (navegación existente). Accesible vía [InkWell] (foco visible + ripple).
class ManagementTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool animate;

  const ManagementTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.animate = true,
  });

  @override
  State<ManagementTile> createState() => _ManagementTileState();
}

class _ManagementTileState extends State<ManagementTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: _hover && widget.animate
            ? Matrix4.translationValues(0.0, -3.0, 0.0)
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        child: GlassCard(
          padding: EdgeInsets.zero,
          borderColor: _hover ? AppColors.primary : null,
          glow: _hover ? AppColors.primary : null,
          child: Material(
            color: Colors.transparent,
            borderRadius: AppRadius.medium,
            child: InkWell(
              borderRadius: AppRadius.medium,
              onTap: widget.onTap,
              hoverColor: Colors.transparent,
              splashColor: AppColors.primary.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 3,
                      height: 36,
                      margin: const EdgeInsets.only(right: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: _hover ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(22),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTypography.subtitle2.copyWith(
                              color: AppColors.darkTextPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.darkTextSecondary,
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
