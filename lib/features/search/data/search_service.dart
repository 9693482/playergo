import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> searchPlayers({
    String? sportId,
    String? positionId,
    String? cityId,
  }) async {
    var query = _client
        .from('players')
        .select('*, profiles!inner(full_name, photo_url, city_id, verification_status)')
        .eq('availability_status', true);

    if (sportId != null) {
      query = query.eq('sport_id', sportId);
    }
    if (positionId != null) {
      query = query.eq('position_id', positionId);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getSports() async {
    final data = await _client
        .from('sports')
        .select()
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getPositions(String sportId) async {
    final data = await _client
        .from('positions')
        .select()
        .eq('sport_id', sportId)
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final data = await _client
        .from('countries')
        .select()
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getRegions(String countryId) async {
    final data = await _client
        .from('regions')
        .select()
        .eq('country_id', countryId)
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getCities(String regionId) async {
    final data = await _client
        .from('cities')
        .select()
        .eq('region_id', regionId)
        .eq('is_active', true)
        .order('name');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getVenues({String? cityId}) async {
    var query = _client
        .from('venues')
        .select()
        .eq('is_active', true);

    if (cityId != null) {
      query = query.eq('city_id', cityId);
    }

    final data = await query.order('name');
    return List<Map<String, dynamic>>.from(data);
  }
}
