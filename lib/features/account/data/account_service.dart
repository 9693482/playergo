import 'package:supabase_flutter/supabase_flutter.dart';

/// Eliminación de la cuenta y datos personales del usuario autenticado.
/// Delega la baja real (auth.admin.deleteUser + cascade) a la Edge Function
/// `delete-account`, que usa la service role en el backend.
class AccountService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> deleteAccount() async {
    final res = await _client.functions.invoke('delete-account');
    if (res.status >= 400) {
      final data = res.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'No se pudo eliminar la cuenta';
      throw Exception(message);
    }
  }

  /// Reenvía el correo de confirmación (verificación de email).
  Future<void> resendEmailConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.email,
      email: email,
    );
  }
}
