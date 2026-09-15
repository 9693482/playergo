import 'package:flutter/material.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final docs = await _verificationService.getPendingDocuments();
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveDocument(IdentityDocument doc) async {
    await _verificationService.approveDocument(doc.id);
    await _loadDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento aprobado'),
          backgroundColor: AppColors.success,
        ),
      );
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
          style: AppTypography.h3.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          style: AppTypography.body1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Motivo del rechazo',
            labelStyle: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(
                color: AppColors.darkTextSecondary.withAlpha(100),
              ),
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
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(
              'Rechazar',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _verificationService.rejectDocument(doc.id, result);
      await _loadDocuments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento rechazado'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Verificaciones pendientes',
            style: AppTypography.h2.copyWith(color: AppColors.darkTextPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Error al cargar documentos',
                  style: AppTypography.subtitle1.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: _loadDocuments,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Verificaciones pendientes',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ResponsiveContainer(
        maxWidth: 960,
        child: _documents.isEmpty
            ? EmptyState(
                illustration: Icons.verified_user_outlined,
                title: 'Todo verificado',
                message: 'No hay documentos pendientes por revisar.',
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: AppRadius.medium,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getDocTypeName(doc.documentType),
                              style: AppTypography.subtitle2.copyWith(
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withAlpha(25),
                                borderRadius: AppRadius.small,
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
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _rejectDocument(doc),
                                icon: const Icon(Icons.close),
                                label: const Text('Rechazar'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approveDocument(doc),
                                icon: const Icon(Icons.check),
                                label: const Text('Aprobar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  String _getDocTypeName(String type) {
    switch (type) {
      case 'CEDULA_CIUDADANIA':
        return 'Cedula de Ciudadania';
      case 'CEDULA_EXTRANJERIA':
        return 'Cedula de Extranjeria';
      case 'PASAPORTE':
        return 'Pasaporte';
      case 'NIT':
        return 'NIT';
      case 'RUT':
        return 'RUT';
      default:
        return type;
    }
  }
}
