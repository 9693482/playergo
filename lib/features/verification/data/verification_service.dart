import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IdentityDocument {
  final String id;
  final String userId;
  final String documentType;
  final String documentNumber;
  final String? documentFrontUrl;
  final String? documentBackUrl;
  final String? selfieUrl;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  IdentityDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.documentNumber,
    this.documentFrontUrl,
    this.documentBackUrl,
    this.selfieUrl,
    this.status = 'PENDING',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory IdentityDocument.fromMap(Map<String, dynamic> map) {
    return IdentityDocument(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      documentType: map['document_type'] as String,
      documentNumber: map['document_number'] as String,
      documentFrontUrl: map['document_front_url'] as String?,
      documentBackUrl: map['document_back_url'] as String?,
      selfieUrl: map['selfie_url'] as String?,
      status: map['status'] as String,
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class VerificationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<IdentityDocument?> getMyDocument() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('identity_documents')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data != null ? IdentityDocument.fromMap(data) : null;
  }

  Future<IdentityDocument> submitDocument({
    required String documentType,
    required String documentNumber,
    String? documentFrontUrl,
    String? documentBackUrl,
    String? selfieUrl,
  }) async {
    final userId = _client.auth.currentUser!.id;

    final existing = await _client
        .from('identity_documents')
        .select('id')
        .eq('user_id', userId)
        .eq('document_type', documentType)
        .maybeSingle();

    if (existing != null) {
      final data = await _client
          .from('identity_documents')
          .update({
            'document_number': documentNumber,
            'document_front_url': ?documentFrontUrl,
            'document_back_url': ?documentBackUrl,
            'selfie_url': ?selfieUrl,
            'status': 'PENDING',
            'rejection_reason': null,
          })
          .eq('id', existing['id'] as String)
          .select()
          .single();

      await _client
          .from('profiles')
          .update({'verification_status': 'PENDING'})
          .eq('id', userId);

      return IdentityDocument.fromMap(data);
    }

    final data = await _client.from('identity_documents').insert({
      'user_id': userId,
      'document_type': documentType,
      'document_number': documentNumber,
      'document_front_url': documentFrontUrl,
      'document_back_url': documentBackUrl,
      'selfie_url': selfieUrl,
      'status': 'PENDING',
    }).select().single();

    await _client
        .from('profiles')
        .update({'verification_status': 'PENDING'})
        .eq('id', userId);

    return IdentityDocument.fromMap(data);
  }

  /// Sube una foto del documento (o selfie) al bucket de Storage y
  /// devuelve la URL pública. [kind] ∈ {front, back, selfie}.
  Future<String> uploadDocumentImage(XFile image, String kind) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No autenticado');

    final bytes = await image.readAsBytes();
    final ext = image.name.split('.').last.toLowerCase();
    final name = '${kind}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '${user.id}/$name';

    await _client.storage.from('identity-documents').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: image.mimeType,
            upsert: true,
          ),
        );

    return _client.storage.from('identity-documents').getPublicUrl(path);
  }

  Future<List<IdentityDocument>> getPendingDocuments() async {
    final data = await _client
        .from('identity_documents')
        .select()
        .eq('status', 'PENDING')
        .order('created_at', ascending: true);

    return (data as List).map((d) => IdentityDocument.fromMap(d)).toList();
  }

  Future<void> approveDocument(String documentId) async {
    final doc = await _client
        .from('identity_documents')
        .select('user_id')
        .eq('id', documentId)
        .single();

    await _client.from('identity_documents').update({
      'status': 'VERIFIED',
      'reviewed_by': _client.auth.currentUser?.id,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', documentId);

    await _client
        .from('profiles')
        .update({'verification_status': 'VERIFIED'})
        .eq('id', doc['user_id']);
  }

  Future<void> rejectDocument(String documentId, String reason) async {
    final doc = await _client
        .from('identity_documents')
        .select('user_id')
        .eq('id', documentId)
        .single();

    await _client.from('identity_documents').update({
      'status': 'REJECTED',
      'reviewed_by': _client.auth.currentUser?.id,
      'reviewed_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', documentId);

    await _client
        .from('profiles')
        .update({'verification_status': 'REJECTED'})
        .eq('id', doc['user_id']);
  }
}
