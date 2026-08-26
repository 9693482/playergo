import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_view.dart';
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
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadDisputes();
  }

  Future<void> _loadDisputes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _disputeService.getAllOpenDisputes();
      setState(() {
        _disputes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
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
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 600,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StateView(
                  isLoading: _isLoading,
                  error: _error,
                  onRetry: _loadDisputes,
                  child: _disputes.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadDisputes,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _disputes.length,
                            itemBuilder: (context, index) {
                              final d = _disputes[index];
                              final statusColor = _getStatusColor(d.status);

                              return AnimatedEntrance(
                                animate: animate,
                                delay: Duration(milliseconds: index * 60),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(AppSpacing.lg),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Player',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.darkTextPrimary,
                      ),
                    ),
                    TextSpan(
                      text: 'GO',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.darkTextPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary,
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: AnimatedEntrance(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.gavel_outlined,
                  size: 56,
                  color: AppColors.darkTextSecondary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No hay disputas abiertas',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.darkTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Si tienes un problema con una reserva, repórtalo y lo resolveremos.',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
