import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/glass_card.dart';

class AppError {
  final String id;
  final String level;
  final String message;
  final String? errorText;
  final String? stackTrace;
  final String? screen;
  final String? userId;
  final String? platform;
  final DateTime createdAt;

  AppError({
    required this.id,
    required this.level,
    required this.message,
    this.errorText,
    this.stackTrace,
    this.screen,
    this.userId,
    this.platform,
    required this.createdAt,
  });

  factory AppError.fromMap(Map<String, dynamic> map) {
    return AppError(
      id: map['id'] as String,
      level: map['level'] as String,
      message: map['message'] as String,
      errorText: map['error_text'] as String?,
      stackTrace: map['stack_trace'] as String?,
      screen: map['screen'] as String?,
      userId: map['user_id'] as String?,
      platform: map['platform'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class AdminErrorsScreen extends StatefulWidget {
  const AdminErrorsScreen({super.key});

  @override
  State<AdminErrorsScreen> createState() => _AdminErrorsScreenState();
}

class _AdminErrorsScreenState extends State<AdminErrorsScreen> {
  final SupabaseClient _client = Supabase.instance.client;
  List<AppError> _errors = [];
  bool _isLoading = true;
  String? _filterLevel;
  int _page = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    AppLogger.setCurrentScreen('AdminErrors');
    _loadErrors();
  }

  @override
  void dispose() {
    AppLogger.setCurrentScreen('');
    super.dispose();
  }

  Future<void> _loadErrors() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      var query = _client.from('app_errors').select();

      if (_filterLevel != null) {
        query = query.eq('level', _filterLevel!);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(0, _pageSize - 1);

      if (mounted) {
        setState(() {
          _errors = (data as List).map((e) => AppError.fromMap(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    _page++;
    try {
      var query = _client.from('app_errors').select();

      if (_filterLevel != null) {
        query = query.eq('level', _filterLevel!);
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(_page * _pageSize, (_page + 1) * _pageSize - 1);

      if (mounted) {
        setState(() {
          _errors.addAll(
            (data as List).map((e) => AppError.fromMap(e)).toList(),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteError(String id) async {
    try {
      await _client.from('app_errors').delete().eq('id', id);
      if (mounted) {
        setState(() => _errors.removeWhere((e) => e.id == id));
      }
    } catch (_) {}
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'FATAL':
        return const Color(0xFF9C27B0);
      case 'ERROR':
        return AppColors.error;
      case 'WARN':
        return AppColors.warning;
      case 'INFO':
        return AppColors.info;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animate = !reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(animate),
            _buildFilterBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _errors.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadErrors,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            itemCount: _errors.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _errors.length) {
                                return _buildLoadMoreButton();
                              }
                              final error = _errors[index];
                              return AnimatedEntrance(
                                delay: Duration(
                                  milliseconds: 60 * index.clamp(0, 10),
                                ),
                                animate: animate,
                                child: _ErrorCard(
                                  error: error,
                                  levelColor: _getLevelColor(error.level),
                                  onDelete: () => _deleteError(error.id),
                                ),
                              );
                            },
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.bug_report, color: AppColors.error, size: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Errores de la app',
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
              gradient: LinearGradient(colors: [AppColors.error, AppColors.warning]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            'Filtrar:',
            style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterChip(
            label: 'Todos',
            isSelected: _filterLevel == null,
            onTap: () => setState(() { _filterLevel = null; _page = 0; }),
          ),
          _FilterChip(
            label: 'ERROR',
            isSelected: _filterLevel == 'ERROR',
            color: AppColors.error,
            onTap: () => setState(() { _filterLevel = 'ERROR'; _page = 0; }),
          ),
          _FilterChip(
            label: 'FATAL',
            isSelected: _filterLevel == 'FATAL',
            color: const Color(0xFF9C27B0),
            onTap: () => setState(() { _filterLevel = 'FATAL'; _page = 0; }),
          ),
          _FilterChip(
            label: 'WARN',
            isSelected: _filterLevel == 'WARN',
            color: AppColors.warning,
            onTap: () => setState(() { _filterLevel = 'WARN'; _page = 0; }),
          ),
          const Spacer(),
          Text(
            '${_errors.length} errores',
            style: AppTypography.caption.copyWith(color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success.withAlpha(150)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Sin errores',
            style: AppTypography.h3.copyWith(color: AppColors.darkTextPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No se han registrado errores.',
            style: AppTypography.body2.copyWith(color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: TextButton(
          onPressed: _loadMore,
          child: Text(
            'Cargar más',
            style: AppTypography.body2.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary).withAlpha(30)
                : AppColors.darkSurfaceVariant,
            borderRadius: AppRadius.full,
            border: Border.all(
              color: isSelected ? (color ?? AppColors.primary) : AppColors.darkSurfaceVariant,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isSelected ? (color ?? AppColors.primary) : AppColors.darkTextSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatefulWidget {
  final AppError error;
  final Color levelColor;
  final VoidCallback onDelete;

  const _ErrorCard({
    required this.error,
    required this.levelColor,
    required this.onDelete,
  });

  @override
  State<_ErrorCard> createState() => _ErrorCardState();
}

class _ErrorCardState extends State<_ErrorCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.levelColor,
                      borderRadius: AppRadius.full,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: widget.levelColor.withAlpha(25),
                                borderRadius: AppRadius.full,
                              ),
                              child: Text(
                                widget.error.level,
                                style: AppTypography.caption.copyWith(
                                  color: widget.levelColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (widget.error.screen != null) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                widget.error.screen!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.darkTextSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: AppColors.darkTextSecondary,
                              onPressed: () => widget.onDelete(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.error.message,
                          style: AppTypography.body2.copyWith(
                            color: AppColors.darkTextPrimary,
                          ),
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.darkTextSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(color: AppColors.darkSurfaceVariant, height: 1),
              const SizedBox(height: AppSpacing.md),
              if (widget.error.errorText != null) ...[
                Text(
                  'Error:',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.error.errorText!,
                  style: AppTypography.body2.copyWith(
                    color: AppColors.error,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (widget.error.stackTrace != null) ...[
                Text(
                  'Stack Trace:',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.darkTextSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.darkBackground,
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    widget.error.stackTrace!,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.darkTextSecondary,
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                    maxLines: 20,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  if (widget.error.platform != null) ...[
                    Icon(Icons.devices, size: 12, color: AppColors.darkTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      widget.error.platform!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.darkTextSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Icon(Icons.access_time, size: 12, color: AppColors.darkTextSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.error.createdAt.day}/${widget.error.createdAt.month}/${widget.error.createdAt.year} ${widget.error.createdAt.hour}:${widget.error.createdAt.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.darkTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
