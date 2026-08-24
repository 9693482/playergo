import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/admin_service.dart';

class AdminDisputesScreen extends StatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  State<AdminDisputesScreen> createState() => _AdminDisputesScreenState();
}

class _AdminDisputesScreenState extends State<AdminDisputesScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _disputes = [];
  bool _isLoading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() => _isLoading = true);
    final data = await _adminService.getAllDisputes(status: _filterStatus);
    setState(() {
      _disputes = data;
      _isLoading = false;
    });
  }

  Future<void> _resolveDispute(Map<String, dynamic> dispute) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Resolver disputa',
          style: AppTypography.h3.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTypography.body1.copyWith(
            color: AppColors.darkTextPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Escribe la resolucion...',
            hintStyle: AppTypography.body2.copyWith(
              color: AppColors.darkTextSecondary,
            ),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(color: AppColors.darkTextSecondary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: BorderSide(
                color: AppColors.darkTextSecondary.withAlpha(100),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.small,
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final resolvedBy = Supabase.instance.client.auth.currentUser?.id ?? '';
      await _adminService.resolveDispute(
        disputeId: dispute['id'],
        resolvedBy: resolvedBy,
        resolution: result,
      );
      await _loadDisputes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disputa resuelta'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN': return AppColors.warning;
      case 'RESOLVED': return AppColors.success;
      case 'CLOSED': return AppColors.darkTextSecondary;
      default: return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Gestionar Disputas',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list, color: AppColors.darkTextPrimary),
            onSelected: (value) {
              setState(() => _filterStatus = value);
              _loadDisputes();
            },
            color: AppColors.darkSurface,
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todas')),
              const PopupMenuItem(value: 'OPEN', child: Text('Abiertas')),
              const PopupMenuItem(value: 'RESOLVED', child: Text('Resueltas')),
              const PopupMenuItem(value: 'CLOSED', child: Text('Cerradas')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _disputes.isEmpty
              ? Center(
                  child: Text(
                    'No hay disputas',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.darkTextSecondary,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDisputes,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: _disputes.length,
                    itemBuilder: (context, index) {
                      final d = _disputes[index];
                      final status = d['status'] ?? '';
                      final statusColor = _getStatusColor(status);

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
                                  Expanded(
                                    child: Text(
                                      d['reason'] ?? '',
                                      style: AppTypography.subtitle2.copyWith(
                                        color: AppColors.darkTextPrimary,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(25),
                                      borderRadius: AppRadius.small,
                                    ),
                                    child: Text(
                                      status,
                                      style: AppTypography.caption.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (d['description'] != null && d['description'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                                  child: Text(
                                    d['description'],
                                    style: AppTypography.body2.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Text(
                                    d['opener_profile']?['full_name'] ?? 'Anonimo',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd/MM HH:mm')
                                        .format(DateTime.parse(d['created_at'])),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.darkTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (status == 'OPEN') ...[
                                const SizedBox(height: AppSpacing.md),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _resolveDispute(d),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Resolver'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.textOnPrimary,
                                    ),
                                  ),
                                ),
                              ],
                              if (d['resolution'] != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withAlpha(25),
                                    borderRadius: AppRadius.small,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          d['resolution'],
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
