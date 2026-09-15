import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/splash_screen.dart';
import '../../../shared/models/enums/enums.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/presentation/player_home_screen.dart';
import '../../reservations/presentation/reservations_screen.dart';
import '../../auth/presentation/login_screen.dart';

/// Resuelve un deep link de reserva (/reservation/:id) hacia la pantalla
/// correcta según el rol del usuario. Base para "abrir reserva desde notificación".
class ReservationDeepLinkScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDeepLinkScreen({required this.reservationId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return profile.when(
      data: (p) {
        if (p == null) return const LoginScreen();
        switch (p.role) {
          case UserRole.team:
            return const ReservationsScreen();
          case UserRole.player:
            return const PlayerHomeScreen();
          case UserRole.admin:
            return const ReservationsScreen();
        }
      },
      loading: () => const SplashScreen(message: 'Abriendo reserva...'),
      error: (_, _) => const PlayerHomeScreen(),
    );
  }
}

/// Navega a un deep link de reserva de forma segura (desde notificaciones).
void goToReservation(BuildContext context, String reservationId) {
  GoRouter.of(context).go('/reservation/$reservationId');
}
