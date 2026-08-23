import 'package:supabase_flutter/supabase_flutter.dart';

class Rating {
  final String id;
  final String reservationId;
  final String raterId;
  final String ratedId;
  final int score;
  final int? punctuality;
  final int? behavior;
  final int? skillLevel;
  final int? compliance;
  final String? comment;
  final DateTime createdAt;
  final String? raterName;

  Rating({
    required this.id,
    required this.reservationId,
    required this.raterId,
    required this.ratedId,
    required this.score,
    this.punctuality,
    this.behavior,
    this.skillLevel,
    this.compliance,
    this.comment,
    required this.createdAt,
    this.raterName,
  });

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      id: map['id'] as String,
      reservationId: map['reservation_id'] as String,
      raterId: map['rater_id'] as String,
      ratedId: map['rated_id'] as String,
      score: map['score'] as int,
      punctuality: map['punctuality'] as int?,
      behavior: map['behavior'] as int?,
      skillLevel: map['skill_level'] as int?,
      compliance: map['compliance'] as int?,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      raterName: map['rater_profile']?['full_name'] as String?,
    );
  }
}

class RatingService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitRating({
    required String reservationId,
    required String raterId,
    required String ratedId,
    required int score,
    int? punctuality,
    int? behavior,
    int? skillLevel,
    int? compliance,
    String? comment,
  }) async {
    final existing = await _client
        .from('ratings')
        .select('id')
        .eq('reservation_id', reservationId)
        .eq('rater_id', raterId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Ya calificaste esta reserva');
    }

    await _client.from('ratings').insert({
      'reservation_id': reservationId,
      'rater_id': raterId,
      'rated_id': ratedId,
      'score': score,
      'punctuality': punctuality,
      'behavior': behavior,
      'skill_level': skillLevel,
      'compliance': compliance,
      'comment': comment,
    });

    await _updateUserRating(ratedId);
  }

  Future<void> _updateUserRating(String ratedId) async {
    final ratings = await _client
        .from('ratings')
        .select('score')
        .eq('rated_id', ratedId);

    if (ratings.isEmpty) return;

    double total = 0;
    for (final r in ratings) {
      total += (r['score'] as int).toDouble();
    }
    final avg = total / ratings.length;

    await _client.from('profiles').update({
      'rating': avg,
    }).eq('id', ratedId);
  }

  Future<List<Rating>> getRatingsForUser(String userId) async {
    final data = await _client
        .from('ratings')
        .select('''
          *,
          rater_profile:profiles!ratings_rater_id_fkey(full_name)
        ''')
        .eq('rated_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((r) => Rating.fromMap(r)).toList();
  }

  Future<Rating?> getRatingForReservation(String reservationId, String raterId) async {
    final data = await _client
        .from('ratings')
        .select()
        .eq('reservation_id', reservationId)
        .eq('rater_id', raterId)
        .maybeSingle();

    return data != null ? Rating.fromMap(data) : null;
  }

  Future<bool> hasRated(String reservationId, String raterId) async {
    final data = await _client
        .from('ratings')
        .select('id')
        .eq('reservation_id', reservationId)
        .eq('rater_id', raterId)
        .maybeSingle();

    return data != null;
  }

  Future<Map<String, dynamic>> getRatingStats(String userId) async {
    final ratings = await getRatingsForUser(userId);

    if (ratings.isEmpty) {
      return {
        'average': 0.0,
        'count': 0,
        'punctuality': 0.0,
        'behavior': 0.0,
        'skillLevel': 0.0,
        'compliance': 0.0,
      };
    }

    double total = 0;
    double pTotal = 0;
    double bTotal = 0;
    double sTotal = 0;
    double cTotal = 0;
    int pCount = 0;
    int bCount = 0;
    int sCount = 0;
    int cCount = 0;

    for (final r in ratings) {
      total += r.score;
      if (r.punctuality != null) { pTotal += r.punctuality!; pCount++; }
      if (r.behavior != null) { bTotal += r.behavior!; bCount++; }
      if (r.skillLevel != null) { sTotal += r.skillLevel!; sCount++; }
      if (r.compliance != null) { cTotal += r.compliance!; cCount++; }
    }

    return {
      'average': total / ratings.length,
      'count': ratings.length,
      'punctuality': pCount > 0 ? pTotal / pCount : 0.0,
      'behavior': bCount > 0 ? bTotal / bCount : 0.0,
      'skillLevel': sCount > 0 ? sTotal / sCount : 0.0,
      'compliance': cCount > 0 ? cTotal / cCount : 0.0,
    };
  }
}
