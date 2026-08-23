import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        return Colors.blue;
      case 'reservation_accepted':
        return Colors.green;
      case 'reservation_rejected':
        return Colors.red;
      case 'payment':
        return Colors.orange;
      case 'chat':
        return Colors.purple;
      default:
        return Colors.grey;
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
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Marcar todo leído'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay notificaciones',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final isRead = notif['is_read'] == true;
                      final type = notif['type'] as String? ?? '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getColor(type).withAlpha(25),
                          child: Icon(
                            _getIcon(type),
                            color: _getColor(type),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notif['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          notif['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatDate(notif['created_at'] ?? ''),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            if (!isRead) ...[
                              const SizedBox(height: 4),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1B5E20),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          _service.markAsRead(notif['id']);
                          setState(() {
                            _notifications[index]['is_read'] = true;
                          });
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
