import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_routes.dart';
import '../../../data/services/message_api_service.dart';
import '../../../data/services/message_notification_service.dart';
import '../../../data/services/websocket_service.dart';
import '../../../data/services/firebase_debug_service.dart';
import '../../../data/services/user_api_service.dart';
import '../../../data/services/item_api_service.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_response_model.dart';
import '../../../data/models/item_response_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/websocket_provider.dart';
import 'widgets/chat_input.dart';
import 'media_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  final TextEditingController _messageController = TextEditingController();
  late MessageApiService _messageApiService;
  late UserApiService _userApiService;
  late ItemApiService _itemApiService;
  late MessageNotificationService _messageNotificationService;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late Future<UserDto> _userFuture;
  StreamSubscription<MessageModel>? _messageSubscription;
  late WebSocketProvider _webSocketProvider;

  // Cache for item details fetched by itemId
  final Map<String, ItemDto> _itemCache = {};

  List<MessageModel> _messages = [];
  List<MessageModel> _optimisticMessages =
      []; // Tin nhắn chưa xác nhận từ server
  bool _isLoadingMessages = true;
  String? _messagesError;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Get auth and WebSocket provider from context
    final authProvider = context.read<AuthProvider>();
    _webSocketProvider = context.read<WebSocketProvider>();

    // Initialize services with auth
    _messageApiService = MessageApiService();
    if (authProvider.accessToken != null) {
      _messageApiService.setAuthToken(authProvider.accessToken!);
      _messageApiService.setGetValidTokenCallback(
        () async => authProvider.accessToken,
      );
    }

    _userApiService = UserApiService();
    if (authProvider.accessToken != null) {
      _userApiService.setAuthToken(authProvider.accessToken!);
      _userApiService.setGetValidTokenCallback(
        () async => authProvider.accessToken,
      );
    }

    _itemApiService = ItemApiService();
    if (authProvider.accessToken != null) {
      _itemApiService.setAuthToken(authProvider.accessToken!);
      _itemApiService.setGetValidTokenCallback(
        () async => authProvider.accessToken,
      );
    }

    // Initialize message notification service
    _messageNotificationService = MessageNotificationService();

    // Initialize WebSocket for real-time messaging
    _setupWebSocket();
    _setupMessageListener();

    _userFuture = _userApiService.getUserById(widget.userId);
    _loadMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  /// Setup WebSocket for real-time messaging
  void _setupWebSocket() {
    try {
      final authProvider = context.read<AuthProvider>();

      if (authProvider.userId == null || authProvider.accessToken == null) {
        print('[ChatScreen] ❌ User ID or access token not available');
        return;
      }

      print('[ChatScreen] 🔌 Setting up WebSocket connection');

      // Connect WebSocket
      _webSocketProvider.connect(
        userId: authProvider.userId!,
        accessToken: authProvider.accessToken!,
      );

      // Listen to incoming messages via WebSocket
      _webSocketProvider.messageStream.listen((message) {
        print('[ChatScreen] 📬 Received message via WebSocket: ${message.id}');

        // Check if message is from the current conversation
        final fromUserId = message.senderId;
        final toUserId = message.receiverId;
        final currentUserId = authProvider.userId;

        final isRelevant =
            (fromUserId == widget.userId && toUserId == currentUserId) ||
                (fromUserId == currentUserId && toUserId == widget.userId);

        if (isRelevant && mounted) {
          print('[ChatScreen] ✅ Message is relevant - updating UI');
          setState(() {
            // Check if message already exists to avoid duplicates
            final messageExists = _messages.any((m) => m.id == message.id);
            if (!messageExists) {
              _messages.insert(0, message);
            }
            // Remove from optimistic messages if it was sent by current user
            if (message.senderId == currentUserId) {
              _optimisticMessages
                  .removeWhere((m) => m.content == message.content);
            }
          });
          _scrollToBottom();
        }
      });

      print('[ChatScreen] ✅ WebSocket setup complete');
    } catch (e) {
      print('[ChatScreen] ❌ Error setting up WebSocket: $e');
    }
  }

  /// Setup listener cho tin nhắn mới từ Firebase
  void _setupMessageListener() {
    // Cancel existing subscription if any
    if (_messageSubscription != null) {
      try {
        _messageSubscription!.cancel();
        print('[ChatScreen] ✅ Cancelled previous subscription');
      } catch (e) {
        print('[ChatScreen] ⚠️  Error cancelling previous subscription: $e');
      }
    } else {
      print(
          '[ChatScreen] ℹ️  No previous subscription to cancel (first setup)');
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.username ?? '';

      print('[ChatScreen] ═══════════════════════════════════════════');
      print('[ChatScreen] 🔄 SETTING UP MESSAGE LISTENER');
      print('[ChatScreen] Current User: $currentUserId');
      print('[ChatScreen] Chat with User: ${widget.userId}');
      print('[ChatScreen] ═══════════════════════════════════════════');

      // Listen to WebSocket messages directly from WebSocketProvider
      _messageSubscription = _webSocketProvider.messageStream.listen(
        (message) {
          print('[ChatScreen] ║');
          print(
              '[ChatScreen] 📨 =============== NEW MESSAGE RECEIVED ===============');
          print('[ChatScreen] ║ Message ID: ${message.id}');
          print('[ChatScreen] ║ From: ${message.senderId}');
          print('[ChatScreen] ║ To: ${message.receiverId}');
          print('[ChatScreen] ║ Content: ${message.content}');

          // Kiểm tra tin nhắn có phải từ cuộc trò chuyện này không
          final fromUserId = message.senderId ?? '';
          final toUserId = message.receiverId ?? '';

          print('[ChatScreen] ║ Current User: $currentUserId');
          print('[ChatScreen] ║ Other User: ${widget.userId}');

          // Tin nhắn có liên quan nếu nó giữa current user và other user
          final isRelevant =
              (fromUserId == widget.userId && toUserId == currentUserId) ||
                  (fromUserId == currentUserId && toUserId == widget.userId);

          if (isRelevant) {
            print(
                '[ChatScreen] ║ ✅ RELEVANT - Message is for this conversation');
            print('[ChatScreen] ║ Reloading messages to show new message...');
            print(
                '[ChatScreen] ║ =======================================================');
            _loadMessages(showLoading: false);
          } else {
            print('[ChatScreen] ║ ⚠️  NOT RELEVANT');
            print(
                '[ChatScreen] ║ Expected: from=${widget.userId}/any, to=${currentUserId}/any');
            print('[ChatScreen] ║ Got: from=$fromUserId, to=$toUserId');
            print(
                '[ChatScreen] ║ =======================================================');
          }
        },
        onError: (error) {
          print('[ChatScreen] ║ ❌ ERROR IN STREAM: $error');
          print('[ChatScreen] ║ Still listening (cancelOnError: false)');
        },
        cancelOnError: false, // Tiếp tục lắng nghe ngay cả khi có error
      );

      print(
          '[ChatScreen] ✅ MESSAGE LISTENER SETUP COMPLETE - Listening to WebSocket');
      print('[ChatScreen] ═══════════════════════════════════════════');

      // ALSO listen to FCM notifications as backup (when WebSocket doesn't deliver or for offline notifications)
      print('[ChatScreen] 🔄 Also setting up FCM notification listener...');
      _messageNotificationService.messageStream.listen(
        (notificationData) {
          print('[ChatScreen] 📲 FCM Notification received in chat screen');
          print(
              '[ChatScreen] 📲 Reference Type: ${notificationData['referenceType']}');
          print(
              '[ChatScreen] 📲 Reference ID: ${notificationData['referenceId']}');

          // When FCM notification arrives, refresh messages (fetch from server)
          // This acts as a fallback/trigger when WebSocket might not deliver instantly
          print(
              '[ChatScreen] 📲 Refreshing messages due to FCM notification...');
          _loadMessages(showLoading: false);
        },
        onError: (error) {
          print('[ChatScreen] 📲 ERROR in FCM stream: $error');
        },
        cancelOnError: false,
      );

      print('[ChatScreen] ✅ FCM listener also setup');
    } catch (e) {
      print('[ChatScreen] ❌ ERROR setting up message listener: $e');
      print('[ChatScreen] ═══════════════════════════════════════════');
    }
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() {
          _isLoadingMessages = true;
          _messagesError = null;
        });
      }

      final messages = await _messageApiService.getConversation(
        otherUserId: widget.userId,
      );

      if (mounted) {
        setState(() {
          _messages = messages;
          _optimisticMessages.clear(); // Xóa tin nhắn tạm khi đã load từ server
          if (showLoading) {
            _isLoadingMessages = false;
          }
          print(
              '[ChatScreen] ✅ Messages updated via setState, count: ${_messages.length}');
        });

        // Mark conversation as read
        _markConversationAsRead();

        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messagesError = e.toString();
          if (showLoading) {
            _isLoadingMessages = false;
          }
          print('[ChatScreen] ❌ Error loading messages: $e');
        });
      }
    }
  }

  /// Mark conversation as read (all unread messages will be marked as read)
  Future<void> _markConversationAsRead() async {
    try {
      await _messageApiService.markConversationAsRead(widget.userId);

      // Update local messages to reflect read status
      if (mounted) {
        setState(() {
          _messages = _messages.map((msg) {
            // Mark messages from other user as read
            if (msg.senderId == widget.userId) {
              return msg.copyWith(readStatus: true);
            }
            return msg;
          }).toList();
        });
      }

      print('[ChatScreen] ✅ Conversation marked as read and updated UI');
    } catch (e) {
      print('[ChatScreen] ⚠️  Error marking conversation as read: $e');
      // Don't show error to user, just log it
    }
  }

  @override
  void dispose() {
    if (_messageSubscription != null) {
      try {
        _messageSubscription!.cancel();
        print('[ChatScreen] ✅ Message subscription cancelled in dispose');
      } catch (e) {
        print('[ChatScreen] ⚠️  Error cancelling subscription in dispose: $e');
      }
    }

    // NOTE: Don't call _webSocketProvider.disconnect() here!
    // WebSocketProvider is a singleton shared across all screens.
    // If we disconnect here, other screens will lose connection.
    // The WebSocket connection should persist across screen navigations.

    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
      print('[ChatScreen] Error fetching item $itemId: $e');
      return null;
    }
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
            // Image with status badge
            Stack(
              children: [
                // Item image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '📦',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
            // Item details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item name
                  Text(
                    item.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Category
                  Text(
                    item.categoryName ?? 'Không xác định',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Quantity and Expiry info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity
                      if (item.quantity != null)
                        Text(
                          'SL: ${item.quantity}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      // Expiry date if available
                      if (item.expiryDate != null)
                        Text(
                          'HSD: ${item.expiryDate!.day}/${item.expiryDate!.month}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
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

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final messageText = _messageController.text;
    _messageController.clear();

    if (_isSending) return;

    // Get current user info from auth provider
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.username ?? 'unknown_user';

    // Create optimistic message
    final optimisticMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      senderName: authProvider.username ?? 'You',
      receiverId: widget.userId,
      receiverName: '', // Will be filled from user data if needed
      content: messageText,
      messageType: 'TEXT',
      readStatus: false,
      createdAt: DateTime.now(),
    );

    // Add message to optimistic list immediately (no loading screen)
    setState(() {
      _optimisticMessages.add(optimisticMessage);
      _isSending = true;
    });

    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);

    try {
      // Send message to backend
      await _messageApiService.sendMessage(
        receiverId: widget.userId,
        content: messageText,
        messageType: 'TEXT',
      );

      // Update conversations cache with current time
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('conversations_cache');
        if (cachedData != null) {
          final List<dynamic> jsonList = jsonDecode(cachedData);
          final conversations = jsonList
              .map((item) =>
                  ConversationModel.fromJson(item as Map<String, dynamic>))
              .toList();

          // Update the conversation with the other user
          final index =
              conversations.indexWhere((c) => c.otherUserId == widget.userId);
          if (index != -1) {
            conversations[index] = ConversationModel(
              otherUserId: conversations[index].otherUserId,
              otherUserName: conversations[index].otherUserName,
              lastMessage: messageText,
              lastMessageAt: DateTime.now(), // Use current time
              unreadCount: 0,
            );

            // Save updated conversations back to cache
            final jsonList = conversations.map((c) => c.toJson()).toList();
            await prefs.setString(
              'conversations_cache',
              jsonEncode(jsonList),
            );
          }
        }
      } catch (e) {
        print('[ChatScreen] Error updating cache: $e');
      }

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }

      // Reload messages in background (no loading screen) to sync with backend
      _loadMessages(showLoading: false);
    } catch (e) {
      if (mounted) {
        // Remove optimistic message on error
        setState(() {
          _optimisticMessages.removeWhere((m) => m.id == optimisticMessage.id);
          _isSending = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _hasEmoji(String text) {
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]|[❤️👍✨]', unicode: true);
    return emojiRegex.hasMatch(text);
  }

  void _addImageAttachment(String filePath, String fileName) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      print('[ChatScreen] 📤 Uploading image to Cloudinary: $fileName');

      // Upload image to Cloudinary
      final imageFile = File(filePath);
      final imageUrl = await _cloudinaryService.uploadMessageImage(imageFile);

      print('[ChatScreen] ✅ Image uploaded successfully: $imageUrl');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Get auth provider for current user
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.username ?? 'unknown_user';

      // Send message with image URL as content
      await _sendMessageWithImage(imageUrl, currentUserId);
    } catch (e) {
      print('[ChatScreen] ❌ Error uploading image: $e');

      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      _showError('Lỗi khi upload ảnh: $e');
    }
  }

  Future<void> _sendMessageWithImage(String imageUrl, String senderId) async {
    try {
      // Create optimistic message
      final optimisticMessage = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: senderId,
        senderName: senderId,
        receiverId: widget.userId,
        receiverName: '',
        content: imageUrl,
        messageType: 'IMAGE',
        readStatus: false,
        createdAt: DateTime.now(),
      );

      // Add to optimistic messages
      setState(() {
        _optimisticMessages.add(optimisticMessage);
        _isSending = true;
      });

      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);

      // Send to backend
      final response = await _messageApiService.sendMessage(
        receiverId: widget.userId,
        content: imageUrl,
        messageType: 'IMAGE',
      );

      print('[ChatScreen] ✅ Message image sent successfully');

      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }

      // Reload messages
      _loadMessages(showLoading: false);
    } catch (e) {
      print('[ChatScreen] ❌ Error sending message image: $e');

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        _showError('Lỗi khi gửi tin nhắn: $e');
      }
    }
  }

  void _addVideoAttachment(String filePath, String fileName) {
    // TODO: Implement video attachment sending via API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng gửi video sẽ sớm được cập nhật'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chọn loại tệp',
              style: AppTextStyles.h4,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primaryTeal),
              title: const Text('Hình ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.video_library, color: AppColors.primaryTeal),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final file = image;
        final fileSizeInMB = await _getFileSize(file.path);

        if (fileSizeInMB > 50) {
          _showFileSizeError('Hình ảnh', fileSizeInMB);
          return;
        }

        _addImageAttachment(file.path, file.name);
      }
    } catch (e) {
      _showError('Lỗi khi chọn hình ảnh: $e');
    }
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final fileSizeInMB = await _getFileSize(video.path);

        if (fileSizeInMB > 50) {
          _showFileSizeError('Video', fileSizeInMB);
          return;
        }

        _addVideoAttachment(video.path, video.name);
      }
    } catch (e) {
      _showError('Lỗi khi chọn video: $e');
    }
  }

  Future<double> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        return file.statSync().size / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _showFileSizeError(String fileType, double sizeMB) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$fileType quá lớn (${sizeMB.toStringAsFixed(2)} MB). Giới hạn là 50 MB.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Test method to verify message listener is working
  void _testMessageUpdate() {
    print('[ChatScreen] 🧪 Testing message update...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing message reload...'),
        duration: Duration(seconds: 2),
      ),
    );
    _loadMessages(showLoading: false);
  }

  /// Show Firebase debug info
  void _showFirebaseDebugInfo() {
    print('[ChatScreen] 🔥 Showing Firebase debug info');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 Firebase Debug Info'),
        content: const SingleChildScrollView(
          child: Text(
            'Firebase debug info has been printed to console.\n\n'
            'Open DevTools or run:\n'
            'flutter logs | grep -E "Firebase|FCM|Permission"\n\n'
            'Check the console for:\n'
            '✅ FCM Token\n'
            '✅ Permission Status\n'
            '✅ Firebase Status',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Print debug info to console
    FirebaseDebugService.printFullDebugInfo();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAttachmentWidget(Map<String, dynamic> attachment) {
    final attachmentType = attachment['type'];
    final isLocal = attachment['isLocal'] ?? false;

    switch (attachmentType) {
      case 'image':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () =>
                _viewMedia(attachment['url'], 'image', attachment['name']),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isLocal
                  ? Image.file(
                      File(attachment['url']),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    )
                  : Image.network(
                      attachment['url'],
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
            ),
          ),
        );

      case 'video':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () =>
                _viewMedia(attachment['url'], 'video', attachment['name']),
            child: Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  isLocal
                      ? Image.file(
                          File(attachment['url']),
                          width: 200,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[300]);
                          },
                        )
                      : Image.network(
                          attachment['url'],
                          width: 200,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[300]);
                          },
                        ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        attachment['duration'] ?? '0:30',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _viewMedia(String url, String mediaType, String fileName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPreviewScreen(
          mediaUrl: url,
          mediaType: mediaType,
          fileName: fileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            // Pop with true to indicate list should refresh
            context.pop(true);
          },
        ),
        title: FutureBuilder<UserDto>(
          future: _userFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final user = snapshot.data!;
              return Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: user.avatar != null && user.avatar!.isNotEmpty
                          ? Image.network(
                              user.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.backgroundGray,
                                  child: const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.backgroundGray,
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // Loading state
            return Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 50,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryTeal),
            onPressed: () {},
          ),
          // Test button for debugging real-time messages
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoadingMessages
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                    ),
                  )
                : _messagesError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Lỗi: $_messagesError'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadMessages(showLoading: true),
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : (_messages.isEmpty && _optimisticMessages.isEmpty)
                        ? const Center(
                            child: Text('Chưa có tin nhắn nào'),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                _messages.length + _optimisticMessages.length,
                            itemBuilder: (context, index) {
                              final isOptimistic = index >= _messages.length;
                              final message = isOptimistic
                                  ? _optimisticMessages[
                                      index - _messages.length]
                                  : _messages[index];
                              final isUserMessage =
                                  message.senderId != widget.userId;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Align(
                                  alignment: isUserMessage
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: isUserMessage
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isUserMessage
                                              ? AppColors.primaryTeal
                                                  .withOpacity(0.2)
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.75,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Debug: Print message type
                                            Builder(
                                              builder: (context) {
                                                final isImageUrl = message
                                                        .content
                                                        .startsWith(
                                                            'http://') ||
                                                    message.content
                                                        .startsWith('https://');
                                                final isCloudinaryUrl =
                                                    message.content.contains(
                                                        'res.cloudinary.com');
                                                final preview =
                                                    message.content.length > 50
                                                        ? message.content
                                                            .substring(0, 50)
                                                        : message.content;
                                                print(
                                                    '[ChatScreen] Message - Type: "${message.messageType}", IsImageUrl: $isImageUrl, IsCloudinary: $isCloudinaryUrl, Content: "$preview..."');
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                            // Display based on message type IMAGE or if content is a URL (cloudinary, vietqr, etc)
                                            if (message.messageType
                                                        .toUpperCase() ==
                                                    'IMAGE' ||
                                                (message.content.startsWith(
                                                        'http://') ||
                                                    message.content.startsWith(
                                                        'https://')))
                                              GestureDetector(
                                                onTap: () =>
                                                    _showFullscreenImage(
                                                        message.content),
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    maxWidth: 300,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.network(
                                                      message.content,
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        print(
                                                            '[ChatScreen] Image load error: $error');
                                                        return Container(
                                                          width: 200,
                                                          height: 200,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors
                                                                .grey[300],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              )
                                            else
                                              // Text content
                                              Text(
                                                message.content,
                                                style: AppTextStyles.bodySmall,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _formatTime(message.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          if (isUserMessage) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              message.readStatus == 'READ'
                                                  ? Icons.done_all
                                                  : Icons.done,
                                              size: 14,
                                              color:
                                                  message.readStatus == 'READ'
                                                      ? Colors.blue
                                                      : Colors.grey,
                                            ),
                                          ],
                                        ],
                                      ),
                                      // Display item card if message has itemId
                                      if (message.itemId != null &&
                                          message.itemId!.isNotEmpty)
                                        FutureBuilder<ItemDto?>(
                                          future:
                                              _fetchItemById(message.itemId!),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                child: SizedBox(
                                                  height: 100,
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.7,
                                                  child:
                                                      const CircularProgressIndicator(
                                                    color:
                                                        AppColors.primaryTeal,
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
                                ),
                              );
                            },
                          ),
          ),
          // Chat input
          ChatInput(
            messageController: _messageController,
            onSendMessage: _sendMessage,
            onAttachmentPressed: _onAttachmentPressed,
          ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  String _formatTime(DateTime dateTime) {
    // Convert to local timezone if it's in UTC
    final localDateTime = dateTime.isUtc ? dateTime.toLocal() : dateTime;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate =
        DateTime(localDateTime.year, localDateTime.month, localDateTime.day);

    if (messageDate == today) {
      return '${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${localDateTime.day}/${localDateTime.month}';
    }
  }

  void _showFullscreenImage(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => FullscreenImageViewer(
        imageUrl: imageUrl,
        onDownload: () => _downloadImage(imageUrl),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      print('[ChatScreen] Download image started: $imageUrl');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang tải về...')),
      );

      // Download the image
      print('[ChatScreen] Downloading image from: $imageUrl');
      final response = await http.get(Uri.parse(imageUrl));
      print('[ChatScreen] Download response code: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Get Downloads directory
        final directory = await getDownloadsDirectory();
        if (directory == null) {
          throw Exception('Không thể lấy thư mục Downloads');
        }

        // Create Shario subfolder
        final sharioDir = Directory('${directory.path}/Shario');
        if (!await sharioDir.exists()) {
          await sharioDir.create(recursive: true);
        }

        // Create filename from timestamp
        final fileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${sharioDir.path}/$fileName';

        // Write file
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('[ChatScreen] Image saved to: $filePath');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ảnh đã được lưu vào Downloads/Shario!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Lỗi khi tải về: ${response.statusCode}');
      }
    } catch (e) {
      print('[ChatScreen] Download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class FullscreenImageViewer extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onDownload;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    required this.onDownload,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animationController.forward(from: 0.0);
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Colors.white),
              onPressed: _resetZoom,
              tooltip: 'Reset zoom',
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: widget.onDownload,
              tooltip: 'Tải về',
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(80.0),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lỗi tải ảnh',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
