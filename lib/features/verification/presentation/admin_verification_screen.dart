import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_view.dart';
import '../data/verification_service.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() => _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  final _verificationService = VerificationService();
  List<IdentityDocument> _documents = [];
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _verificationService.getPendingDocuments();
      if (mounted) {
        setState(() {
          _documents = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approveDocument(IdentityDocument doc) async {
    try {
      await _verificationService.approveDocument(doc.id);
      await _loadDocuments();
      if (mounted) {
        AppFeedback.showSuccess(context, 'Documento aprobado');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error al aprobar documento');
      }
    }
  }

  Future<void> _rejectDocument(IdentityDocument doc) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Rechazar documento',
          style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
        ),
        content: TextField(
          controller: controller,
          style: AppTypography.body1.copyWith(color: AppColors.darkTextPrimary),
          decoration: InputDecoration(
            labelText: 'Motivo del rechazo',
            labelStyle: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(color: AppColors.darkTextSecondary.withAlpha(100)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rechazar', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _verificationService.rejectDocument(doc.id, result);
        await _loadDocuments();
        if (mounted) {
          AppFeedback.showSuccess(context, 'Documento rechazado');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Error al rechazar documento');
        }
      }
    }
  }

  void _showFullScreenImage(String? url, String title) {
    if (url == null || url.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.subtitle1.copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54, size: 48),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(animate),
            Expanded(
              child: StateView(
                isLoading: _isLoading,
                error: _error,
                onRetry: _loadDocuments,
                child: _documents.isEmpty
                    ? EmptyState(
                        illustration: Icons.verified_user_outlined,
                        title: 'Todo verificado',
                        message: 'No hay documentos pendientes por revisar.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final doc = _documents[index];
                            return AnimatedEntrance(
                              delay: Duration(milliseconds: 80 * index.clamp(0, 10)),
                              animate: animate,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _getDocTypeName(doc.documentType),
                                          style: AppTypography.subtitle1.copyWith(
                                            color: AppColors.darkTextPrimary,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md, vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withAlpha(25),
                                            borderRadius: AppRadius.full,
                                          ),
                                          child: Text(
                                            'Pendiente',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Documento: ${doc.documentNumber}',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      'Enviado: ${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.darkTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _buildPhotoSection(doc),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _rejectDocument(doc),
                                            icon: const Icon(Icons.close, size: 18),
                                            label: const Text('Rechazar'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppColors.error,
                                              side: const BorderSide(color: AppColors.error),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _approveDocument(doc),
                                            icon: const Icon(Icons.check, size: 18),
                                            label: const Text('Aprobar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.success,
                                              foregroundColor: AppColors.textOnPrimary,
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                   ),
                                ),
                              );
                           },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(IdentityDocument doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos',
          style: AppTypography.caption.copyWith(
            color: AppColors.darkTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (doc.documentFrontUrl != null && doc.documentFrontUrl!.isNotEmpty)
              _photoThumbnail(
                url: doc.documentFrontUrl!,
                label: 'Frente',
                onTap: () => _showFullScreenImage(doc.documentFrontUrl!, 'Documento - Frente'),
              ),
            if (doc.documentBackUrl != null && doc.documentBackUrl!.isNotEmpty)
              _photoThumbnail(
                url: doc.documentBackUrl!,
                label: 'Reverso',
                onTap: () => _showFullScreenImage(doc.documentBackUrl!, 'Documento - Reverso'),
              ),
            if (doc.selfieUrl != null && doc.selfieUrl!.isNotEmpty)
              _photoThumbnail(
                url: doc.selfieUrl!,
                label: 'Selfie',
                onTap: () => _showFullScreenImage(doc.selfieUrl!, 'Selfie de verificación'),
              ),
            if ((doc.documentFrontUrl == null || doc.documentFrontUrl!.isEmpty) &&
                (doc.documentBackUrl == null || doc.documentBackUrl!.isEmpty) &&
                (doc.selfieUrl == null || doc.selfieUrl!.isEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  'Sin fotos adjuntas',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _photoThumbnail({
    required String url,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.small,
          border: Border.all(color: AppColors.darkSurfaceVariant),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, color: AppColors.darkTextSecondary, size: 20),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.darkTextSecondary,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool animate) {
    return AnimatedEntrance(
      animate: animate,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Text('🔍', style: AppTypography.h2),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Verificaciones pendientes',
                    style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
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

  String _getDocTypeName(String type) {
    switch (type) {
      case 'CEDULA_CIUDADANIA': return 'Cédula de Ciudadanía';
      case 'CEDULA_EXTRANJERIA': return 'Cédula de Extranjería';
      case 'PASAPORTE': return 'Pasaporte';
      case 'NIT': return 'NIT';
      case 'RUT': return 'RUT';
      default: return type;
    }
  }
}
