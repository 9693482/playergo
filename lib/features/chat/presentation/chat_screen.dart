import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _chatService.markAsRead(widget.chatId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.chatId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await _chatService.sendMessage(widget.chatId, text);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.darkSurfaceVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.darkTextPrimary,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Text(
                    widget.otherName,
                    style: AppTypography.subtitle1.copyWith(
                      color: AppColors.darkTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.darkSurfaceVariant,
                    child: Text(
                      widget.otherName[0].toUpperCase(),
                      style: AppTypography.subtitle2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _messages.isEmpty
                      ? Center(
                          child: Text(
                            'Envía el primer mensaje',
                            style: AppTypography.body2.copyWith(
                              color: AppColors.darkTextSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(AppSpacing.lg),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMine =
                                msg.senderRole == _getMyRole();

                            return _MessageBubble(
                              message: msg,
                              isMine: isMine,
                              time: _formatTime(msg.createdAt),
                            );
                          },
                        ),
            ),
            _MessageInput(
              controller: _controller,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  String _getMyRole() {
    return 'player';
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final String time;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.darkSurfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft:
                Radius.circular(isMine ? AppRadius.lg : 4),
            bottomRight:
                Radius.circular(isMine ? 4 : AppRadius.lg),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: AppTypography.body1.copyWith(
                color: isMine
                    ? AppColors.textOnPrimary
                    : AppColors.darkTextPrimary,
                fontSize: 15,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: AppTypography.caption.copyWith(
                    color: isMine
                        ? AppColors.textOnPrimary
                            .withValues(alpha: 0.7)
                        : AppColors.darkTextSecondary,
                    fontSize: 11,
                  ),
                ),
                if (isMine) ...[
                  SizedBox(width: AppSpacing.xs),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppColors.info
                        : AppColors.textOnPrimary
                            .withValues(alpha: 0.7),
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

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(
            color: AppColors.darkSurfaceVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTypography.body1.copyWith(
                  color: AppColors.darkTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: AppTypography.body1.copyWith(
                    color: AppColors.darkTextSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.full,
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurfaceVariant,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 22,
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
