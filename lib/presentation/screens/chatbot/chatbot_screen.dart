import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with WidgetsBindingObserver {
  late MessageApiService _messageApiService;
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Chatbot ID - cần thay với actual chatbot ID từ backend
  static const String CHATBOT_ID = 'chatbot';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageApiService = MessageApiService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _messageApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setGetValidTokenCallback(
          () async => authProvider.accessToken,
        );
      }

      _loadChatbotConversation();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadChatbotConversation();
    }
  }

  Future<void> _loadChatbotConversation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final backendMessages = await _messageApiService.getConversation(
        otherUserId: CHATBOT_ID,
        limit: 100,
      );

      setState(() {
        // Keep local user messages and merge with backend messages
        final currentUserId = context.read<AuthProvider>().username ?? '';
        final userLocalMessages =
            _messages.where((m) => m.senderId == currentUserId).toList();

        // Combine backend messages with local user messages
        // Backend messages take priority (in case they were updated)
        final backendIds = backendMessages.map((m) => m.id).toSet();
        final localOnlyMessages =
            userLocalMessages.where((m) => !backendIds.contains(m.id)).toList();

        // Merge: backend messages + local-only user messages
        final mergedMessages = [...backendMessages, ...localOnlyMessages];

        // Sort by timestamp
        mergedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        _messages = mergedMessages;
        _isLoading = false;
      });

      // Mark conversation as read
      try {
        await _messageApiService.markConversationAsRead(CHATBOT_ID);
      } catch (e) {
        print('[ChatbotScreen] Error marking as read: $e');
      }

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('[ChatbotScreen] Error loading conversation: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String content) async {
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      // Add optimistic message
      final userMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: context.read<AuthProvider>().username ?? '',
        senderName: context.read<AuthProvider>().username ?? 'You',
        receiverId: CHATBOT_ID,
        receiverName: 'Chatbot',
        content: content,
        messageType: 'TEXT',
        readStatus: true,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(userMessage);
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });

      // Send to API (Chatbot endpoint)
      try {
        final response = await _messageApiService.sendChatbotMessage(
          message: content,
        );
        print('[ChatbotScreen] Chatbot response: $response');

        // Extract chatbot's response from the API response
        if (response.containsKey('data')) {
          final botResponseText = response['data'];

          // Create a message from chatbot response
          final botMessage = MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_bot',
            senderId: CHATBOT_ID,
            senderName: 'Chatbot',
            receiverId: context.read<AuthProvider>().username ?? '',
            receiverName: context.read<AuthProvider>().username ?? 'User',
            content: botResponseText.toString(),
            messageType: 'TEXT',
            readStatus: true,
            createdAt: DateTime.now(),
          );

          // Add bot message to UI
          setState(() {
            _messages.add(botMessage);
          });

          // Scroll to bottom
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } catch (sendError) {
        print('[ChatbotScreen] Error sending to chatbot: $sendError');
      }

      // Reload conversation to sync with backend (optional, since we already show the response)
      // await Future.delayed(const Duration(milliseconds: 500));
      // await _loadChatbotConversation();
    } catch (e) {
      print('[ChatbotScreen] Error in message flow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.username ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shario Chatbot',
              style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
            ),
            Text(
              'Trợ giúp 24/7',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hãy bắt đầu hội thoại',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isSentByUser =
                              message.senderId == currentUserId;

                          return Align(
                            alignment: isSentByUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSentByUser
                                    ? AppColors.primaryGreen
                                    : AppColors.backgroundGray,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                message.content,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isSentByUser
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppColors.borderLight,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) {
                        _sendMessage(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(_messageController.text),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
