import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/player_home_screen.dart';
import '../../features/home/presentation/team_home_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reservations/presentation/reservation_deep_link_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../../features/legal/presentation/legal_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/team/presentation/create_team_screen.dart';
import '../../shared/models/enums/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final liveSession = Supabase.instance.client.auth.currentSession != null;
      final isLoggedIn = liveSession ||
          (authState.whenOrNull(
                data: (data) => data.session != null,
              ) ??
              false);

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isOnboarding = state.matchedLocation == '/onboarding';

      final onboardingDone = ref
              .read(sharedPreferencesProvider)
              .getBool('onboarding_completed') ??
          false;

      if (!isLoggedIn) {
        if (isAuthRoute || isOnboarding) return null;
        return onboardingDone ? '/login' : '/onboarding';
      }

      if (isAuthRoute || isOnboarding) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (context, state) => ReservationDeepLinkScreen(
          reservationId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const LegalScreen(type: 'terms'),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const LegalScreen(type: 'privacy'),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: '/create-team',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return profile.when(
            data: (p) {
              if (p == null) {
                return Scaffold(
                  backgroundColor: AppColors.darkBackground,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: AppColors.warning),
                        const SizedBox(height: 16),
                        Text(
                          'Sesión iniciada, pero tu perfil\nno está en la base de datos.',
                          textAlign: TextAlign.center,
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Regístrate de nuevo para crearlo.',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/register'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                          child: const Text('Ir a registro'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              switch (p.role) {
                case UserRole.player:
                  return const PlayerHomeScreen();
                case UserRole.team:
                  return const TeamHomeScreen();
                case UserRole.admin:
                  return const AdminDashboardScreen();
              }
            },
            loading: () => const SplashScreen(message: 'Cargando tu cuenta...'),
            error: (e, _) => const _ProfileMissingScreen(),
          );
        },
      ),
    ],
  );
});

class _ProfileMissingScreen extends StatelessWidget {
  const _ProfileMissingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu perfil no está configurado',
                style: AppTypography.h3.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cierra sesión y vuelve a registrarte.',
                style: AppTypography.body2.copyWith(
                  color: AppColors.darkTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
