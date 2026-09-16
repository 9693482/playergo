import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final data = await _service.getNotifications();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  Future<void> _markAllRead() async {
    await _service.markAllAsRead();
    await _loadNotifications();
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'reservation_request':
        return Icons.calendar_month;
      case 'reservation_accepted':
        return Icons.check_circle;
      case 'reservation_rejected':
        return Icons.cancel;
      case 'payment':
        return Icons.attach_money;
      case 'chat':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'reservation_request':
        return AppColors.info;
      case 'reservation_accepted':
        return AppColors.success;
      case 'reservation_rejected':
        return AppColors.error;
      case 'payment':
        return AppColors.warning;
      case 'chat':
        return AppColors.primary;
      default:
        return AppColors.darkTextSecondary;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return DateFormat('dd/MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Notificaciones',
          style: AppTypography.h2.copyWith(
            color: AppColors.darkTextPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Marcar todo leído',
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const SkeletonList()
          : Column(
              children: [
                Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.success,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _notifications.isEmpty
                      ? const EmptyState(
                          illustration: Icons.notifications_none,
                          title: 'No hay notificaciones',
                          message:
                              'Te avisaremos cuando pase algo importante.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: AppColors.primary,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            itemCount: _notifications.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(
                                    height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final notif =
                                  _notifications[index];
                              final isRead =
                                  notif['is_read'] == true;
                              final type =
                                  notif['type'] as String? ?? '';

                              return AnimatedEntrance(
                                delay: Duration(
                                    milliseconds: index * 60),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(
                                      AppSpacing.lg),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _getColor(type)
                                              .withAlpha(25),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _getIcon(type),
                                          color:
                                              _getColor(type),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(
                                              notif['title'] ??
                                                  '',
                                              style: AppTypography
                                                  .subtitle1
                                                  .copyWith(
                                                color: AppColors
                                                    .darkTextPrimary,
                                                fontWeight: isRead
                                                    ? FontWeight
                                                        .w500
                                                    : FontWeight
                                                        .w700,
                                              ),
                                            ),
                                            const SizedBox(
                                                height: AppSpacing.xs),
                                            Text(
                                              notif['body'] ??
                                                  '',
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow
                                                      .ellipsis,
                                              style: AppTypography
                                                  .body2
                                                  .copyWith(
                                                color: AppColors
                                                    .darkTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              AppSpacing.sm),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .end,
                                        children: [
                                          Text(
                                            _formatDate(
                                                notif['created_at'] ??
                                                    ''),
                                            style: AppTypography
                                                .caption
                                                .copyWith(
                                              color: AppColors
                                                  .darkTextSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(
                                                height: 4),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration:
                                                  const BoxDecoration(
                                                color: AppColors
                                                    .primary,
                                                shape: BoxShape
                                                    .circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
