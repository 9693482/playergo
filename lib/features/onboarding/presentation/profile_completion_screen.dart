import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/enums/enums.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedSport;
  String? _selectedPosition;
  bool _isSaving = false;
  bool _photoUploading = false;
  String? _photoUrl;

  final _sports = [
    'Fútbol', 'Baloncesto', 'Voleibol', 'Tenis',
    'Pádel', 'Bádminton', 'Futsal', 'Básquetbol',
  ];

  final _positions = [
    'Portero', 'Defensa', 'Mediocampista', 'Delantero',
    'Base', 'Escolta', 'Alero', 'Ala-Pívot', 'Pívot',
    'Receptor', 'Colocador', 'Líbero',
    'Solo/a', 'Sin posición preferida',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _photoUrl = profile.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() => _photoUploading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final url = await authService.uploadProfilePhoto(image);
      setState(() {
        _photoUrl = url;
        _photoUploading = false;
      });
      ref.invalidate(currentProfileProvider);
    } catch (e) {
      setState(() => _photoUploading = false);
      if (mounted) {
        AppFeedback.showError(context, 'Error al subir foto');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final profile = ref.read(currentProfileProvider).valueOrNull;
      if (profile == null) return;

      final authService = ref.read(authServiceProvider);
      final updatedProfile = profile.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      await authService.updateProfile(updatedProfile);

      ref.invalidate(currentProfileProvider);
      ref.invalidate(currentPlayerProvider);

      if (mounted) {
        AppFeedback.showSuccess(context, 'Perfil completado');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final role = profile.valueOrNull?.role;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildPhotoSection(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildNameSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPhoneSection(),
                      if (role == UserRole.player) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _buildSportSection(),
                        const SizedBox(height: AppSpacing.lg),
                        _buildPositionSection(),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _buildSaveButton(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSkipButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedEntrance(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Text('⚽', style: AppTypography.h1),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completa tu perfil',
                        style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
                      ),
                      Text(
                        'Cuéntanos sobre ti',
                        style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primary, AppColors.success]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTap: _pickPhoto,
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: AppColors.primary,
                  backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                  child: _photoUrl == null
                      ? Text(
                          (_nameController.text.isNotEmpty
                              ? _nameController.text[0]
                              : 'U')
                              .toUpperCase(),
                          style: AppTypography.h1.copyWith(color: AppColors.textOnPrimary),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.darkBackground, width: 3),
                    ),
                    child: _photoUploading
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 18, color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Toca para agregar foto',
              style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 150),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Nombre completo', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: 'Tu nombre',
                hintStyle: AppTypography.body1.copyWith(color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu nombre' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 200),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Teléfono (opcional)', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
              decoration: InputDecoration(
                hintText: '+57 300 123 4567',
                hintStyle: AppTypography.body1.copyWith(color: AppColors.darkTextSecondary),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(80)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.small,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 250),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Deporte', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _sports.map((sport) {
                final isSelected = _selectedSport == sport;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSport = sport),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.darkBackground,
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.darkTextSecondary.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      sport,
                      style: AppTypography.body2.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionSection() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 300),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports, size: 20, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Posición', style: AppTypography.subtitle1.copyWith(color: AppColors.darkTextPrimary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _positions.map((pos) {
                final isSelected = _selectedPosition == pos;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPosition = pos),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withAlpha(30) : AppColors.darkBackground,
                      borderRadius: AppRadius.full,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.darkTextSecondary.withAlpha(80),
                      ),
                    ),
                    child: Text(
                      pos,
                      style: AppTypography.body2.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.darkTextSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 350),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2),
                )
              : Text(
                  'Completar perfil',
                  style: AppTypography.button.copyWith(color: AppColors.textOnPrimary),
                ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedEntrance(
      delay: const Duration(milliseconds: 400),
      child: TextButton(
        onPressed: () => context.go('/'),
        child: Text(
          'Omitir por ahora',
          style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
        ),
      ),
    );
  }
}
