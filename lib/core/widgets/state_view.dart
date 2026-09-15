import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'empty_state.dart';
import 'skeleton.dart';

/// Widget reutilizable para manejar los estados de una carga asíncrona:
/// loading, error (con reintento), vacío y contenido.
/// Es consciente de la conectividad: si no hay red muestra un mensaje específico.
class StateView extends ConsumerWidget {
  final bool isLoading;
  final Object? error;
  final bool isEmpty;
  final String? emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final String? errorTitle;
  final VoidCallback? onRetry;
  final Widget? loading;
  final Widget child;

  const StateView({
    super.key,
    required this.isLoading,
    this.error,
    this.isEmpty = false,
    this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.errorTitle,
    this.onRetry,
    this.loading,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);

    if (isLoading) {
      return loading ?? const SkeletonList();
    }

    if (error != null) {
      return _ErrorView(
        error: error!,
        title: errorTitle,
        offline: !online,
        onRetry: onRetry,
      );
    }

    if (isEmpty) {
      return _EmptyView(
        message: emptyMessage,
        icon: emptyIcon,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }

    return child;
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final String? title;
  final bool offline;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.error,
    this.title,
    this.offline = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isOffline = offline ||
        error.toString().toLowerCase().contains('socket') ||
        error.toString().toLowerCase().contains('network') ||
        error.toString().toLowerCase().contains('connection');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOffline ? Icons.wifi_off : Icons.error_outline,
              size: 56,
              color: isOffline ? AppColors.warning : AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isOffline ? 'Sin conexión' : (title ?? 'Algo salió mal'),
              style: AppTypography.subtitle1.copyWith(
                color: AppColors.darkTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isOffline
                  ? 'Revisa tu conexión a internet e inténtalo de nuevo.'
                  : error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.body2.copyWith(
                color: AppColors.darkTextSecondary,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyView({
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      illustration: icon,
      title: message ?? 'No hay datos para mostrar',
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
