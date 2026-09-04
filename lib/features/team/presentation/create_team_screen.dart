import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _captainPhoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _teamNameController.dispose();
    _captainNameController.dispose();
    _captainPhoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;

      await ref.read(authServiceProvider).createTeam(
            userId: user.id,
            teamName: _teamNameController.text.trim(),
            captainName: _captainNameController.text.trim(),
            captainPhone: _captainPhoneController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );

      ref.invalidate(currentTeamProvider);

      if (mounted) {
        AppFeedback.showSuccess(context, 'Equipo creado exitosamente');
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          'No se pudo crear el equipo: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        title: const Text('Crear equipo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Volver',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.group_add,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Información del equipo',
                                style: AppTypography.subtitle1.copyWith(
                                  color: AppColors.darkTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _buildTextField(
                            controller: _teamNameController,
                            label: 'Nombre del equipo',
                            icon: Icons.group_outlined,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildTextField(
                            controller: _captainNameController,
                            label: 'Nombre del capitán',
                            icon: Icons.person_outlined,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildTextField(
                            controller: _captainPhoneController,
                            label: 'Teléfono del capitán',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Descripción (opcional)',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isLoading ? 'Creando...' : 'Crear equipo',
                        style: AppTypography.button,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTypography.body1.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body2.copyWith(
          color: AppColors.darkTextSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.darkTextSecondary, size: 20),
        filled: true,
        fillColor: AppColors.darkSurfaceVariant.withAlpha(80),
        border: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: BorderSide(
            color: AppColors.darkSurfaceVariant,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.small,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
