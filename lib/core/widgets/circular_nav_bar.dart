import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A single nav item for CircularNavBar.
class CircularNavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CircularNavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Bottom navigation bar with circular active indicator + glow.
class CircularNavBar extends StatelessWidget {
  final List<CircularNavItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CircularNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkSurfaceVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = selectedIndex == i;
              return _CircularNavIcon(
                icon: item.icon,
                activeIcon: item.activeIcon,
                label: item.label,
                isActive: isActive,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CircularNavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _CircularNavIcon({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: isActive ? 48 : 40,
              height: isActive ? 48 : 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? AppColors.primary.withAlpha(35)
                    : Colors.transparent,
                border: isActive
                    ? Border.all(
                        color: AppColors.primary.withAlpha(120),
                        width: 1.5,
                      )
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.darkTextSecondary,
                  size: isActive ? 24 : 20,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.darkTextSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
