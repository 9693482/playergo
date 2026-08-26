import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/animated_entrance.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _chatService = ChatService();
  List<Chat> _chats = [];
  final Map<String, String> _names = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    final chats = await _chatService.getChats();
    for (final chat in chats) {
      final playerName = await _chatService.getPlayerName(chat.playerId);
      final teamName = await _chatService.getTeamName(chat.teamId);
      _names[chat.playerId] = playerName ?? 'Jugador';
      _names[chat.teamId] = teamName ?? 'Equipo';
    }
    setState(() {
      _chats = chats;
      _isLoading = false;
    });
  }

  String _getOtherName(Chat chat) {
    return _names[chat.teamId] ?? _names[chat.playerId] ?? 'Usuario';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'es').format(date);
    }
    return DateFormat('dd/MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const SkeletonList()
                  : _chats.isEmpty
                      ? const EmptyState(
                          illustration: Icons.chat_bubble_outline,
                          title: 'No hay conversaciones aún',
                          message: 'Contacta un jugador o equipo para empezar.',
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChats,
                          color: AppColors.primary,
                          backgroundColor: AppColors.darkSurface,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            itemCount: _chats.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final chat = _chats[index];
                              final otherName = _getOtherName(chat);
                              final hasUnread = chat.unreadCountPlayer > 0 ||
                                  chat.unreadCountTeam > 0;

                              return AnimatedEntrance(
                                delay: Duration(milliseconds: 60 * index),
                                animate: !reduceMotion,
                                child: _ChatItem(
                                  chat: chat,
                                  otherName: otherName,
                                  hasUnread: hasUnread,
                                  date: _formatDate(chat.lastMessageAt),
                                  unreadCount: chat.unreadCountPlayer +
                                      chat.unreadCountTeam,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chat.id,
                                          otherName: otherName,
                                        ),
                                      ),
                                    ).then((_) => _loadChats());
                                  },
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

  Widget _buildHeader() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text(
                '⚽',
                style: AppTypography.h2,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Mensajes',
                style: AppTypography.h2.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(0),
                AppColors.primary,
                AppColors.primary.withAlpha(0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatItem extends StatelessWidget {
  final Chat chat;
  final String otherName;
  final bool hasUnread;
  final String date;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatItem({
    required this.chat,
    required this.otherName,
    required this.hasUnread,
    required this.date,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        borderRadius: AppRadius.lg,
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                otherName[0].toUpperCase(),
                style: AppTypography.h3.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherName,
                    style: AppTypography.subtitle1.copyWith(
                      fontWeight:
                          hasUnread ? FontWeight.bold : FontWeight.w600,
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    chat.lastMessage ?? 'Sin mensajes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body2.copyWith(
                      color: hasUnread
                          ? AppColors.darkTextPrimary
                          : AppColors.darkTextSecondary,
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: AppTypography.caption.copyWith(
                    color: hasUnread
                        ? AppColors.primary
                        : AppColors.darkTextSecondary,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: AppTypography.overline.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
