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

  Future<List<Map<String, dynamic>>> getUserRegistrationTrend() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final data = await _client
        .from('profiles')
        .select('created_at')
        .gte('created_at', sixMonthsAgo.toIso8601String())
        .order('created_at', ascending: true);

    final Map<String, int> monthly = {};
    for (final row in data as List) {
      final date = DateTime.parse(row['created_at'] as String);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + 1;
    }

    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final label = _monthLabel(date.month);
      result.add({
        'month': label,
        'count': monthly[key] ?? 0,
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getReservationTrend() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final data = await _client
        .from('reservations')
        .select('created_at')
        .gte('created_at', sixMonthsAgo.toIso8601String())
        .order('created_at', ascending: true);

    final Map<String, int> monthly = {};
    for (final row in data as List) {
      final date = DateTime.parse(row['created_at'] as String);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + 1;
    }

    final result = <Map<String, dynamic>>[];
    for (int i = 0; i < 6; i++) {
      final date = DateTime(now.year, now.month - 5 + i, 1);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final label = _monthLabel(date.month);
      result.add({
        'month': label,
        'count': monthly[key] ?? 0,
      });
    }
    return result;
  }

  String _monthLabel(int month) {
    const months = [
      '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return months[month];
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

  Future<Map<String, dynamic>?> getUserDetail(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _client.from('profiles').update({
      'role': role,
    }).eq('id', userId);
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

  Future<void> deactivateUser(String userId) async {
    await _client.from('profiles').update({
      'is_active': false,
    }).eq('id', userId);
  }

  Future<void> reactivateUser(String userId) async {
    await _client.from('profiles').update({
      'is_active': true,
    }).eq('id', userId);
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    String? action,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client
        .from('audit_log')
        .select('*, profiles:user_id(full_name, email)');

    if (userId != null) {
      query = query.eq('user_id', userId);
    }
    if (action != null) {
      query = query.eq('action', action);
    }

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(data);
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

  // ============================================================
  // PLATFORM SETTINGS
  // ============================================================

  Future<List<Map<String, dynamic>>> getPlatformSettings() async {
    final data = await _client
        .from('platform_settings')
        .select()
        .order('key', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updatePlatformSetting(String key, String value) async {
    await _client.from('platform_settings').update({
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('key', key);
  }

  // ============================================================
  // CANCELLATION POLICIES
  // ============================================================

  Future<List<Map<String, dynamic>>> getCancellationPolicies() async {
    final data = await _client
        .from('cancellation_policies')
        .select()
        .order('hours_before', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> updateCancellationPolicy({
    required String policyId,
    required int hoursBefore,
    required double refundPercentage,
    required String description,
    required bool isActive,
  }) async {
    await _client.from('cancellation_policies').update({
      'hours_before': hoursBefore,
      'refund_percentage': refundPercentage,
      'description': description,
      'is_active': isActive,
    }).eq('id', policyId);
  }

  // ============================================================
  // PLATFORM STATS SUMMARY
  // ============================================================

  Future<Map<String, dynamic>> getPlatformSummary() async {
    final fees = await _client.from('platform_fees').select('amount');
    final totalRevenue = (fees as List).fold<double>(
      0,
      (sum, f) => sum + (double.tryParse(f['amount'].toString()) ?? 0),
    );

    final settings = await getPlatformSettings();
    final settingsMap = {for (final s in settings) s['key']: s['value']};

    return {
      'totalRevenue': totalRevenue,
      'feeCount': fees.length,
      'settings': settingsMap,
    };
  }
}
