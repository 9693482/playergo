import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Banner global que aparece en la parte superior cuando no hay conexión.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;

  const ConnectivityBanner({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);

    return Column(
      children: [
        if (!online)
          Container(
            width: double.infinity,
            color: AppColors.warning,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.black87, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Sin conexión. Algunas funciones no están disponibles.',
                        style: AppTypography.caption.copyWith(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
