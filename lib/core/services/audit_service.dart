import 'package:supabase_flutter/supabase_flutter.dart';

class AuditService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> log({
    required String action,
    required String entity,
    String? entityId,
    Map<String, dynamic>? details,
  }) async {
    final userId = _client.auth.currentUser?.id;

    await _client.from('audit_log').insert({
      'user_id': userId,
      'action': action,
      'entity': entity,
      'entity_id': entityId,
      'details': details,
    });
  }

  Future<List<Map<String, dynamic>>> getAuditLogs({
    String? userId,
    String? action,
    String? entity,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('audit_log').select();

    if (userId != null) query = query.eq('user_id', userId);
    if (action != null) query = query.eq('action', action);
    if (entity != null) query = query.eq('entity', entity);

    final data = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<bool> checkRateLimit({
    required String userId,
    required String action,
    int windowSeconds = 60,
    int maxCount = 10,
  }) async {
    final result = await _client.rpc('check_rate_limit', params: {
      'p_user_id': userId,
      'p_action': action,
      'p_window_seconds': windowSeconds,
      'p_max_count': maxCount,
    });

    return result as bool? ?? true;
  }
}
