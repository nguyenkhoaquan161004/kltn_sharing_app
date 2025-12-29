import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/bottom_navigation_widget.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/user_api_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_response_model.dart';
import '../../../data/providers/auth_provider.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  late MessageApiService _messageApiService;
  UserApiService? _userApiService;
  late Future<List<ConversationModel>> _conversationsFuture;
  static const String _cacheKey = 'conversations_cache';

  @override
  void initState() {
    super.initState();
    // Initialize services with auth
    final authProvider = context.read<AuthProvider>();

    try {
      _messageApiService = context.read<MessageApiService>();
    } catch (e) {
      _messageApiService = MessageApiService();
    }

    // Setup auth for MessageApiService BEFORE making API calls
    if (authProvider.accessToken != null) {
      _messageApiService.setAuthToken(authProvider.accessToken!);
      _messageApiService.setGetValidTokenCallback(
        () async => authProvider.accessToken,
      );
    }

    // Initialize UserApiService with auth
    _userApiService = UserApiService();
    if (authProvider.accessToken != null) {
      _userApiService!.setAuthToken(authProvider.accessToken!);
      _userApiService!.setGetValidTokenCallback(
        () async => authProvider.accessToken,
      );
    }

    // Load conversations from cache first, then from API
    _conversationsFuture = _loadConversationsWithCache();
  }

  Future<List<ConversationModel>> _loadConversationsWithCache() async {
    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        print('[MessagesListScreen] Loading conversations from cache');
        final List<dynamic> jsonList = jsonDecode(cachedData);
        final cached = jsonList
            .map((item) =>
                ConversationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // Sort conversations by latest message (newest first)
        cached.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

        // Load fresh data from API in background and update cache
        _refreshConversationsInBackground();

        return cached;
      }
    } catch (e) {
      print('[MessagesListScreen] Error loading from cache: $e');
    }

    // If no cache, load from API
    return _fetchAndCacheConversations();
  }

  Future<List<ConversationModel>> _fetchAndCacheConversations() async {
    try {
      print('[MessagesListScreen] Fetching conversations from API');
      var conversations = await _messageApiService.getAllConversations();

      // Sort conversations by latest message (newest first)
      conversations.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

      // Cache the result
      _cacheConversations(conversations);

      return conversations;
    } catch (e) {
      print('[MessagesListScreen] Error fetching conversations: $e');
      rethrow;
    }
  }

  void _refreshConversationsInBackground() async {
    try {
      print('[MessagesListScreen] Refreshing conversations in background');
      final fresh = await _messageApiService.getAllConversations();
      _cacheConversations(fresh);
    } catch (e) {
      print('[MessagesListScreen] Background refresh failed: $e');
    }
  }

  Future<void> _cacheConversations(
      List<ConversationModel> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(jsonList));
      print('[MessagesListScreen] Conversations cached successfully');
    } catch (e) {
      print('[MessagesListScreen] Error caching conversations: $e');
    }
  }

  UserApiService get userApiService {
    if (_userApiService == null) {
      final authProvider = context.read<AuthProvider>();
      _userApiService = UserApiService();
      if (authProvider.accessToken != null) {
        _userApiService!.setAuthToken(authProvider.accessToken!);
        _userApiService!.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }
    }
    return _userApiService!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: const AppHeaderBar(),
      body: FutureBuilder<List<ConversationModel>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lỗi: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _conversationsFuture = _fetchAndCacheConversations();
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có cuộc trò chuyện nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _conversationsFuture = _fetchAndCacheConversations();
              });
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return _buildMessageItem(
                  context,
                  conversations[index],
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 3),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ConversationModel conversation,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to chat screen
        context.push('/chat/${conversation.otherUserId}');
      },
      child: FutureBuilder<UserDto>(
        future: userApiService.getUserById(conversation.otherUserId),
        builder: (context, userSnapshot) {
          final user = userSnapshot.data;
          final isLoading =
              userSnapshot.connectionState == ConnectionState.waiting;
          final hasError = userSnapshot.hasError;

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              color:
                  conversation.unreadCount > 0 ? Colors.grey[50] : Colors.white,
            ),
            child: Row(
              children: [
                // Avatar
                if (isLoading)
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[300],
                  )
                else if (!hasError &&
                    user?.avatar != null &&
                    user!.avatar!.isNotEmpty)
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(user.avatar!),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback to initials
                    },
                  )
                else
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryTeal,
                    child: Text(
                      conversation.otherUserName.isNotEmpty
                          ? conversation.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Message info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (user != null && !hasError)
                                  ? user.fullName
                                  : conversation.otherUserName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: conversation.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(conversation.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: conversation.unreadCount > 0
                              ? AppColors.textPrimary
                              : Colors.grey[600],
                          fontWeight: conversation.unreadCount > 0
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${conversation.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa đây';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}p';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
