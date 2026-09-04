import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/responsive/responsive.dart';
import '../data/verification_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _verificationService = VerificationService();
  final _picker = ImagePicker();
  IdentityDocument? _document;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isUploading = false;

  XFile? _frontImage;
  XFile? _backImage;
  XFile? _selfieImage;
  String? _frontUrl;
  String? _backUrl;
  String? _selfieUrl;

  final _documentNumberController = TextEditingController();
  String _selectedDocType = 'CEDULA_CIUDADANIA';

  final _docTypes = {
    'CEDULA_CIUDADANIA': 'Cédula de Ciudadanía',
    'CEDULA_EXTRANJERIA': 'Cédula de Extranjería',
    'PASAPORTE': 'Pasaporte',
    'NIT': 'NIT',
    'RUT': 'RUT',
  };

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    final doc = await _verificationService.getMyDocument();
    setState(() {
      _document = doc;
      if (doc != null) {
        _selectedDocType = doc.documentType;
        _documentNumberController.text = doc.documentNumber;
      }
      _isLoading = false;
    });
  }

  Future<String?> _uploadIfNeeded(XFile? image, String kind) async {
    if (image == null) return null;
    return _verificationService.uploadDocumentImage(image, kind);
  }

  Future<void> _pick(void Function(XFile) setImage) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) setImage(image);
  }

  Future<void> _submitDocument() async {
    if (_documentNumberController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      setState(() => _isUploading = true);
      try {
        _frontUrl ??= await _uploadIfNeeded(_frontImage, 'front');
        _backUrl ??= await _uploadIfNeeded(_backImage, 'back');
        _selfieUrl ??= await _uploadIfNeeded(_selfieImage, 'selfie');
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }

      await _verificationService.submitDocument(
        documentType: _selectedDocType,
        documentNumber: _documentNumberController.text.trim(),
        documentFrontUrl: _frontUrl,
        documentBackUrl: _backUrl,
        selfieUrl: _selfieUrl,
      );

      await _loadDocument();

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          'Documento enviado para revisión',
        );
      }
    } catch (e) {
      AppLogger.error('Error enviando documento de verificación', e);
      if (mounted) {
        AppFeedback.showError(
          context,
          e is AuthException || e is PostgrestException
              ? e.toString()
              : 'No se pudo enviar el documento',
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Color _getStatusColor() {
    switch (_document?.status) {
      case 'VERIFIED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _getStatusText() {
    switch (_document?.status) {
      case 'VERIFIED':
        return 'Verificado';
      case 'PENDING':
        return 'En revisión';
      case 'REJECTED':
        return 'Rechazado';
      default:
        return 'Sin verificar';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    'PlayerGO',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Volver',
                  ),
                ],
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.success,
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ResponsiveContainer(
                  maxWidth: 600,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedEntrance(
                        delay: Duration.zero,
                        child: _buildStatusCard(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Datos del documento',
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: _buildDocumentFields(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: Text(
                          'Fotos del documento',
                          style: AppTypography.subtitle1.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: _buildPhotoFields(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 360),
                        child: Text(
                          'Sube fotos nítidas de tu documento (frente y reverso) y un selfie para completar la verificación.',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 400),
                        child: _buildSubmitButton(),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
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

  Widget _buildStatusCard() {
    final color = _getStatusColor();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, size: 24, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Estado de verificación',
                style: AppTypography.subtitle1.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: AppRadius.full,
            ),
            child: Text(
              _getStatusText(),
              style: AppTypography.subtitle2.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_document?.rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Motivo: ${_document!.rejectionReason}',
              style: AppTypography.body2.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentFields() {
    return GlassCard(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedDocType,
            dropdownColor: AppColors.darkSurfaceVariant,
            style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
            decoration: InputDecoration(
              labelText: 'Tipo de documento',
              labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: const BorderSide(color: AppColors.darkSurfaceVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.small,
              ),
            ),
            items: _docTypes.entries
                .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedDocType = value);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _documentNumberController,
            style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
            decoration: InputDecoration(
              labelText: 'Número de documento',
              labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: const BorderSide(color: AppColors.darkSurfaceVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.small,
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoFields() {
    return Row(
      children: [
        Expanded(
          child: _PhotoField(
            label: 'Frente',
            image: _frontImage,
            onTap: () => _pick((f) => setState(() => _frontImage = f)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PhotoField(
            label: 'Reverso',
            image: _backImage,
            onTap: () => _pick((f) => setState(() => _backImage = f)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _PhotoField(
            label: 'Selfie',
            image: _selfieImage,
            onTap: () => _pick((f) => setState(() => _selfieImage = f)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting || _isUploading ? null : _submitDocument,
        icon: _isSubmitting || _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkTextPrimary),
              )
            : const Icon(Icons.send, color: AppColors.darkTextPrimary),
        label: Text(
          _isSubmitting || _isUploading ? 'Enviando...' : 'Enviar para revisión',
          style: AppTypography.button.copyWith(color: AppColors.darkTextPrimary),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.darkTextPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
      ),
    );
  }
}

class _PhotoField extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;

  const _PhotoField({
    required this.label,
    this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 0.75,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.darkSurfaceVariant),
            borderRadius: AppRadius.medium,
            color: AppColors.darkSurfaceVariant.withAlpha(40),
          ),
          child: image != null
              ? ClipRRect(
                  borderRadius: AppRadius.medium,
                  child: Image.network(image!.path, fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 28, color: AppColors.darkTextSecondary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.darkTextSecondary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
