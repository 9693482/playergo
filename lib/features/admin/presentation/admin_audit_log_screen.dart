import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/state_view.dart';
import '../data/admin_service.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final _adminService = AdminService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _filterAction;

  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _loadLogs(reset: true);
  }

  Future<void> _loadLogs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _logs = [];
        _hasMore = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final offset = reset ? 0 : _logs.length;
      final logs = await _adminService.getAuditLogs(
        action: _filterAction,
        limit: _pageSize,
        offset: offset,
      );
      setState(() {
        if (reset) {
          _logs = logs;
        } else {
          _logs.addAll(logs);
        }
        _hasMore = logs.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('ban')) return AppColors.error;
    if (action.contains('verify') || action.contains('approved')) return AppColors.success;
    if (action.contains('reject')) return AppColors.error;
    if (action.contains('create') || action.contains('insert')) return AppColors.primary;
    if (action.contains('update')) return AppColors.info;
    if (action.contains('delete')) return AppColors.error;
    return AppColors.darkTextSecondary;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('ban')) return Icons.block;
    if (action.contains('verify') || action.contains('approved')) return Icons.verified;
    if (action.contains('reject')) return Icons.cancel;
    if (action.contains('create') || action.contains('insert')) return Icons.add_circle;
    if (action.contains('update')) return Icons.edit;
    if (action.contains('delete')) return Icons.delete;
    return Icons.info_outline;
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
                onRetry: () => _loadLogs(reset: true),
                child: _logs.isEmpty
                    ? EmptyState(
                        illustration: Icons.history,
                        title: 'Sin actividad',
                        message: 'Las acciones administradas aparecerán aquí.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadLogs(reset: true),
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _logs.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _logs.length) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: Center(
                                  child: _isLoadingMore
                                      ? const CircularProgressIndicator(color: AppColors.primary)
                                      : ElevatedButton.icon(
                                          onPressed: () => _loadLogs(),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Cargar más'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.darkSurface,
                                            foregroundColor: AppColors.darkTextPrimary,
                                          ),
                                        ),
                                ),
                              );
                            }

                            final log = _logs[index];
                            final action = log['action'] ?? '';
                            final entity = log['entity'] ?? '';
                            final entityId = log['entity_id'] ?? '';
                            final details = log['details'];
                            final createdAt = log['created_at'] != null
                                ? DateTime.tryParse(log['created_at']) : null;
                            final userProfile = log['profiles'];
                            final userName = userProfile?['full_name'] ?? 'Sistema';
                            final userEmail = userProfile?['email'] ?? '';

                              return AnimatedEntrance(
                                delay: Duration(milliseconds: 40 * index.clamp(0, 20)),
                                animate: animate,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                  child: GlassCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: _getActionColor(action).withAlpha(30),
                                        borderRadius: AppRadius.small,
                                      ),
                                      child: Icon(
                                        _getActionIcon(action),
                                        color: _getActionColor(action),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  action.toUpperCase(),
                                                  style: AppTypography.caption.copyWith(
                                                    color: _getActionColor(action),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (createdAt != null)
                                                Text(
                                                  DateFormat('dd/MM/yy HH:mm').format(createdAt),
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.darkTextSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$entity • $userName',
                                            style: AppTypography.body2.copyWith(
                                              color: AppColors.darkTextPrimary,
                                            ),
                                          ),
                                          if (userEmail.isNotEmpty)
                                            Text(
                                              userEmail,
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.darkTextSecondary,
                                              ),
                                            ),
                                          if (entityId.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: entityId));
                                                },
                                                child: Text(
                                                  'ID: ${entityId.toString().substring(0, entityId.toString().length.clamp(0, 12))}...',
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.darkTextSecondary,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (details != null && details is Map)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkBackground,
                                                  borderRadius: AppRadius.small,
                                                ),
                                                child: Text(
                                                  details.toString(),
                                                  style: AppTypography.caption.copyWith(
                                                    color: AppColors.darkTextSecondary,
                                                    fontSize: 10,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
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
                Text('📜', style: AppTypography.h2),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Historial de auditoría',
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
}
