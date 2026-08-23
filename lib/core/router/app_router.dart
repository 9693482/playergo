import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/player_home_screen.dart';
import '../../features/home/presentation/team_home_screen.dart';
import '../../shared/models/enums/enums.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(currentProfileProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.whenOrNull(
            data: (data) => data.session != null,
          ) ??
          false;

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) {
          return profile.when(
            data: (p) {
              if (p == null) return const _LoadingScreen();

              switch (p.role) {
                case UserRole.player:
                  return const PlayerHomeScreen();
                case UserRole.team:
                  return const TeamHomeScreen();
                case UserRole.admin:
                  return const PlayerHomeScreen();
              }
            },
            loading: () => const _LoadingScreen(),
            error: (e, _) => const _LoadingScreen(),
          );
        },
      ),
    ],
  );
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 80, color: Color(0xFF1B5E20)),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFF1B5E20)),
          ],
        ),
      ),
    );
  }
}
