import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/dispute_service.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  final _disputeService = DisputeService();
  List<Dispute> _disputes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    final data = await _disputeService.getAllOpenDisputes();
    setState(() {
      _disputes = data;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return AppColors.warning;
      case 'RESOLVED':
        return AppColors.success;
      case 'CLOSED':
        return AppColors.darkTextSecondary;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'OPEN':
        return 'Abierta';
      case 'RESOLVED':
        return 'Resuelta';
      case 'CLOSED':
        return 'Cerrada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Disputas',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _disputes.isEmpty
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(AppSpacing.xxl),
                    padding: const EdgeInsets.all(AppSpacing.xxxl),
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: AppRadius.medium,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.gavel,
                          size: 56,
                          color: AppColors.darkTextSecondary,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No hay disputas abiertas',
                          style: AppTypography.body1.copyWith(
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
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
                      final statusColor = _getStatusColor(d.status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: AppRadius.medium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    d.reason,
                                    style: AppTypography.subtitle2.copyWith(
                                      color: AppColors.darkTextPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(30),
                                    borderRadius: AppRadius.full,
                                  ),
                                  child: Text(
                                    _getStatusText(d.status),
                                    style: AppTypography.caption.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (d.description != null && d.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Text(
                                  d.description!,
                                  style: AppTypography.body2.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: AppColors.darkTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  d.openerName ?? 'Anonimo',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.darkTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(d.createdAt),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.darkTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (d.resolution != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Divider(
                                color: AppColors.darkSurfaceVariant,
                                height: 1,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Resolucion: ${d.resolution}',
                                      style: AppTypography.body2.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
