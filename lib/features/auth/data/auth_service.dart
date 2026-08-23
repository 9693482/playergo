import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/validators/validators.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/player.dart';
import '../../../shared/models/team.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    final cleanEmail = Validators.sanitize(email) ?? email;
    final cleanName = Validators.sanitize(fullName) ?? fullName;

    final response = await _client.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'full_name': cleanName,
        'role': role,
      },
    );

    if (response.user != null) {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'email': cleanEmail,
        'full_name': cleanName,
        'role': role,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = Validators.sanitize(email) ?? email;
    return await _client.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    final cleanEmail = Validators.sanitize(email) ?? email;
    await _client.auth.resetPasswordForEmail(cleanEmail);
  }

  Future<Profile?> getProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final data = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  Future<Player?> getPlayer(String userId) async {
    final data = await _client
        .from('players')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Player.fromJson(data);
  }

  Future<Player> createPlayer({
    required String userId,
    required String sportId,
    required String positionId,
    required double pricePerMatch,
    String? bio,
    int experienceYears = 0,
  }) async {
    final cleanBio = Validators.sanitize(bio);
    final data = await _client
        .from('players')
        .insert({
          'user_id': userId,
          'sport_id': sportId,
          'position_id': positionId,
          'price_per_match': pricePerMatch,
          'bio': cleanBio,
          'experience_years': experienceYears,
        })
        .select()
        .single();

    return Player.fromJson(data);
  }

  Future<Team?> getTeam(String userId) async {
    final data = await _client
        .from('teams')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Team.fromJson(data);
  }

  Future<Team> createTeam({
    required String userId,
    required String teamName,
    String? description,
    String? captainName,
    String? captainPhone,
  }) async {
    final cleanName = Validators.sanitize(teamName) ?? teamName;
    final cleanDesc = Validators.sanitize(description);
    final cleanCaptain = Validators.sanitize(captainName);

    final data = await _client
        .from('teams')
        .insert({
          'user_id': userId,
          'team_name': cleanName,
          'description': cleanDesc,
          'captain_name': cleanCaptain,
          'captain_phone': captainPhone,
        })
        .select()
        .single();

    return Team.fromJson(data);
  }
}
