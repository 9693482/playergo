import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final data = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return data?['role'] == 'ADMIN';
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final users = await _client.from('profiles').select('id');
    final players = await _client.from('players').select('id');
    final teams = await _client.from('teams').select('id');
    final reservations = await _client.from('reservations').select('id');
    final activeReservations = await _client
        .from('reservations')
        .select('id')
        .inFilter('status', ['PENDING', 'ACCEPTED', 'CONFIRMED']);
    final disputes = await _client
        .from('disputes')
        .select('id')
        .eq('status', 'OPEN');

    return {
      'totalUsers': (users as List).length,
      'totalPlayers': (players as List).length,
      'totalTeams': (teams as List).length,
      'totalReservations': (reservations as List).length,
      'activeReservations': (activeReservations as List).length,
      'openDisputes': (disputes as List).length,
    };
  }

  Future<List<Map<String, dynamic>>> getAllUsers({
    String? role,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('profiles')
        .select();

    if (role != null) {
      query = query.eq('role', role);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> banUser(String userId) async {
    await _client.from('profiles').update({
      'verification_status': 'REJECTED',
    }).eq('id', userId);
  }

  Future<void> unbanUser(String userId) async {
    await _client.from('profiles').update({
      'verification_status': 'VERIFIED',
    }).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAllReservations({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('reservations')
        .select();

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getAllDisputes({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('disputes')
        .select('''
          *,
          opener_profile:profiles!disputes_opened_by_fkey(full_name)
        ''');

    if (status != null) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> resolveDispute({
    required String disputeId,
    required String resolvedBy,
    required String resolution,
  }) async {
    await _client.from('disputes').update({
      'status': 'RESOLVED',
      'resolution': resolution,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', disputeId);
  }
}
