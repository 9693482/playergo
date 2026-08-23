import 'package:supabase_flutter/supabase_flutter.dart';

class Chat {
  final String id;
  final String playerId;
  final String teamId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCountPlayer;
  final int unreadCountTeam;
  final DateTime createdAt;
  final String? playerName;
  final String? teamName;

  Chat({
    required this.id,
    required this.playerId,
    required this.teamId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCountPlayer = 0,
    this.unreadCountTeam = 0,
    required this.createdAt,
    this.playerName,
    this.teamName,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id'] as String,
      playerId: map['player_id'] as String,
      teamId: map['team_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      unreadCountPlayer: map['unread_count_player'] as int? ?? 0,
      unreadCountTeam: map['unread_count_team'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      playerName: map['player_profile']?['full_name'] as String?,
      teamName: map['team_profile']?['full_name'] as String?,
    );
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderRole;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as String,
      chatId: map['chat_id'] as String,
      senderId: map['sender_id'] as String,
      senderRole: map['sender_role'] as String,
      content: map['content'] as String,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class ChatService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<Chat>> getChats() async {
    final profileId = _currentUserId;

    final data = await _client
        .from('chats')
        .select('''
          *,
          player:players!chats_player_id_fkey(
            id,
            profile:profiles(full_name)
          ),
          team:teams!chats_team_id_fkey(
            id,
            profile:profiles(full_name)
          )
        ''')
        .or('player_id.eq.${await _getPlayerId(profileId)},team_id.eq.${await _getTeamId(profileId)}')
        .order('last_message_at', ascending: false);

    return (data as List).map((chat) {
      final playerProfile = chat['player']?['profile'] as Map<String, dynamic>?;
      final teamProfile = chat['team']?['profile'] as Map<String, dynamic>?;
      return Chat(
        id: chat['id'] as String,
        playerId: chat['player_id'] as String,
        teamId: chat['team_id'] as String,
        lastMessage: chat['last_message'] as String?,
        lastMessageAt: chat['last_message_at'] != null
            ? DateTime.parse(chat['last_message_at'] as String)
            : null,
        unreadCountPlayer: chat['unread_count_player'] as int? ?? 0,
        unreadCountTeam: chat['unread_count_team'] as int? ?? 0,
        createdAt: DateTime.parse(chat['created_at'] as String),
        playerName: playerProfile?['full_name'] as String?,
        teamName: teamProfile?['full_name'] as String?,
      );
    }).toList();
  }

  Future<String?> _getPlayerId(String profileId) async {
    final data = await _client
        .from('players')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<String?> _getTeamId(String profileId) async {
    final data = await _client
        .from('teams')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();
    return data?['id'] as String?;
  }

  Future<Chat> getOrCreateChat(String playerId, String teamId) async {
    final existing = await _client
        .from('chats')
        .select()
        .eq('player_id', playerId)
        .eq('team_id', teamId)
        .maybeSingle();

    if (existing != null) {
      return Chat.fromMap(existing);
    }

    final created = await _client
        .from('chats')
        .insert({
          'player_id': playerId,
          'team_id': teamId,
        })
        .select()
        .single();

    return Chat.fromMap(created);
  }

  Future<List<Message>> getMessages(String chatId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return (data as List).map((m) => Message.fromMap(m)).toList();
  }

  Future<void> sendMessage(String chatId, String content) async {
    final profileId = _currentUserId;
    final playerId = await _getPlayerId(profileId);
    final teamId = await _getTeamId(profileId);

    final senderRole = playerId != null ? 'player' : 'team';
    final senderId = playerId ?? teamId;

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
    });
  }

  Future<void> markAsRead(String chatId) async {
    final profileId = _currentUserId;
    final playerId = await _getPlayerId(profileId);

    if (playerId != null) {
      await _client
          .from('chats')
          .update({'unread_count_player': 0})
          .eq('id', chatId);
    } else {
      await _client
          .from('chats')
          .update({'unread_count_team': 0})
          .eq('id', chatId);
    }

    await _client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', await _getSenderId());
  }

  Future<String> _getSenderId() async {
    final profileId = _currentUserId;
    final playerId = await _getPlayerId(profileId);
    if (playerId != null) return playerId;
    return (await _getTeamId(profileId))!;
  }

  Stream<List<Message>> watchMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) => data.map((m) => Message.fromMap(m)).toList());
  }

  Stream<List<Chat>> watchChats() {
    return _client
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((_) => getChats());
  }
}
