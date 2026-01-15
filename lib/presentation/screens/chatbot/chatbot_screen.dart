import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/auth_token_callback_helper.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/item_response_model.dart';
import '../../../data/providers/auth_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late MessageApiService _messageApiService;
  late ItemApiService _itemApiService;
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isBotTyping = false;
  String? _errorMessage;

  // Cache for item details fetched by itemId
  final Map<String, ItemDto> _itemCache = {};

  // Chatbot ID - cần thay với actual chatbot ID từ backend
  static const String CHATBOT_ID = 'chatbot';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageApiService = MessageApiService();
    _itemApiService = ItemApiService();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.accessToken != null) {
        _messageApiService.setAuthToken(authProvider.accessToken!);
        _messageApiService.setGetValidTokenCallback(
          createTokenExpiredCallback(context),
        );
        _itemApiService.setAuthToken(authProvider.accessToken!);
        _itemApiService.setGetValidTokenCallback(
          createTokenExpiredCallback(context),
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

  /// Build item card for shared items (when message has itemId)
  Future<ItemDto?> _fetchItemById(String itemId) async {
    // Check cache first
    if (_itemCache.containsKey(itemId)) {
      return _itemCache[itemId];
    }

    try {
      final item = await _itemApiService.getItem(itemId);
      if (item != null) {
        _itemCache[itemId] = item;
      }
      return item;
    } catch (e) {
      print('[ChatbotScreen] Error fetching item $itemId: $e');
      return null;
    }
  }

  /// Extract itemId from chatbot response text
  /// Format: ||ITEM:uuid||
  String? _extractItemId(String text) {
    final pattern = RegExp(r'\|\|ITEM:([a-f0-9\-]+)\|\|');
    final match = pattern.firstMatch(text);
    return match?.group(1);
  }

  /// Remove itemId marker from text to display
  String _cleanupResponseText(String text) {
    return text.replaceAll(RegExp(r'\|\|ITEM:[a-f0-9\-]+\|\|'), '').trim();
  }

  /// Build a shared item card widget for displaying in message
  Widget _buildItemCardForMessage(ItemDto item) {
    return GestureDetector(
      onTap: () {
        context.push('/item/${item.id}');
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.imageUrl ?? 'https://via.placeholder.com/300x200',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: AppColors.backgroundGray,
                    child: const Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
            // Item details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  if (item.categoryName != null)
                    Text(
                      item.categoryName!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (item.price ?? 0) == 0 ? 'Miễn phí' : '${item.price} đ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Xem chi tiết',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        _isBotTyping = true; // Show typing indicator
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
          final botResponseText = response['data'].toString();

          // Extract itemId if present
          final itemId = _extractItemId(botResponseText);

          // Clean up the response text (remove itemId marker)
          final cleanedText = _cleanupResponseText(botResponseText);

          // Create a message from chatbot response
          final botMessage = MessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_bot',
            senderId: CHATBOT_ID,
            senderName: 'Chatbot',
            receiverId: context.read<AuthProvider>().username ?? '',
            receiverName: context.read<AuthProvider>().username ?? 'User',
            content: cleanedText,
            messageType: 'TEXT',
            readStatus: true,
            createdAt: DateTime.now(),
            itemId: itemId, // Set itemId if found
          );

          // Add bot message to UI
          setState(() {
            _messages.add(botMessage);
            _isBotTyping = false; // Hide typing indicator
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
        setState(() {
          _isBotTyping = false; // Hide typing indicator on error
        });
      }

      // Reload conversation to sync with backend (optional, since we already show the response)
      // await Future.delayed(const Duration(milliseconds: 500));
      // await _loadChatbotConversation();
    } catch (e) {
      print('[ChatbotScreen] Error in message flow: $e');
      setState(() {
        _isBotTyping = false; // Hide typing indicator on error
      });
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
                : _messages.isEmpty && !_isBotTyping
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
                        itemCount: _messages.length + (_isBotTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Typing indicator
                          if (_isBotTyping && index == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundGray,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TypingIndicator(),
                              ),
                            );
                          }

                          final message = _messages[index];
                          final isSentByUser =
                              message.senderId == currentUserId;

                          return Align(
                            alignment: isSentByUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: isSentByUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
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
                                // Display item card if message has itemId
                                if (message.itemId != null &&
                                    message.itemId!.isNotEmpty)
                                  FutureBuilder<ItemDto?>(
                                    future: _fetchItemById(message.itemId!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                          child: SizedBox(
                                            height: 100,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.7,
                                            child:
                                                const CircularProgressIndicator(
                                              color: AppColors.primaryTeal,
                                            ),
                                          ),
                                        );
                                      } else if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        return _buildItemCardForMessage(
                                            snapshot.data!);
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                              ],
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

/// Animated typing indicator widget
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0, end: 8).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              transform:
                  Matrix4.translationValues(0, -_animations[index].value, 0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
