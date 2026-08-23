import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/profile.dart';
import '../../../shared/models/player.dart';
import '../../../shared/models/team.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
    data: (state) => state.session?.user,
  );
});

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final authService = ref.watch(authServiceProvider);
  return authService.getProfile(user.id);
});

final currentPlayerProvider = FutureProvider<Player?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final authService = ref.watch(authServiceProvider);
  return authService.getPlayer(user.id);
});

final currentTeamProvider = FutureProvider<Team?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final authService = ref.watch(authServiceProvider);
  return authService.getTeam(user.id);
});
