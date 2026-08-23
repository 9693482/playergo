import 'package:supabase_flutter/supabase_flutter.dart';

class AvailabilityService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getAvailability(String playerId) async {
    final data = await _client
        .from('player_availability')
        .select()
        .eq('player_id', playerId)
        .order('day_of_week');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> setAvailability({
    required String playerId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isAvailable = true,
  }) async {
    await _client.from('player_availability').upsert({
      'player_id': playerId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
    });
  }

  Future<void> removeAvailability(String playerId, int dayOfWeek) async {
    await _client
        .from('player_availability')
        .delete()
        .eq('player_id', playerId)
        .eq('day_of_week', dayOfWeek);
  }

  Future<List<Map<String, dynamic>>> getBlockedDates(String playerId) async {
    final data = await _client
        .from('player_blocked_dates')
        .select()
        .eq('player_id', playerId)
        .order('blocked_date');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> blockDate({
    required String playerId,
    required String date,
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    await _client.from('player_blocked_dates').insert({
      'player_id': playerId,
      'blocked_date': date,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
    });
  }

  Future<void> unblockDate(String playerId, String date) async {
    await _client
        .from('player_blocked_dates')
        .delete()
        .eq('player_id', playerId)
        .eq('blocked_date', date);
  }
}
