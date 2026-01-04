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
import '../../../data/services/firebase_debug_service.dart';
import '../../../data/services/user_api_service.dart';
import '../../../data/services/cloudinary_service.dart';
import '../../../data/models/message_model.dart';
import '../../../data/models/user_response_model.dart';
import '../../../data/providers/auth_provider.dart';
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
  late MessageNotificationService _messageNotificationService;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  late Future<UserDto> _userFuture;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

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

    // Get auth from provider
    final authProvider = context.read<AuthProvider>();

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

    // Initialize message notification service
    _messageNotificationService = MessageNotificationService();
    _setupMessageListener();

    _userFuture = _userApiService.getUserById(widget.userId);
    _loadMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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

      _messageSubscription = _messageNotificationService.messageStream.listen(
        (messageData) {
          print('[ChatScreen] ║');
          print(
              '[ChatScreen] 📨 =============== NEW MESSAGE RECEIVED ===============');
          print(
              '[ChatScreen] ║ Message data keys: ${messageData.keys.toList()}');
          print('[ChatScreen] ║ Full message: $messageData');

          // Kiểm tra tin nhắn có phải từ cuộc trò chuyện này không
          final fromUserId =
              messageData['fromUserId'] ?? messageData['senderId'] ?? '';
          final toUserId =
              messageData['toUserId'] ?? messageData['receiverId'] ?? '';

          print('[ChatScreen] ║ Message FROM: $fromUserId');
          print('[ChatScreen] ║ Message TO: $toUserId');
          print('[ChatScreen] ║ Current User: $currentUserId');
          print('[ChatScreen] ║ Other User: ${widget.userId}');

          // Tin nhắn có liên quan nếu nó giữa current user và other user
          final isRelevant =
              (fromUserId == widget.userId && toUserId == currentUserId) ||
                  (fromUserId == currentUserId && toUserId == widget.userId);

          if (isRelevant) {
            print('[ChatScreen] ║ ✅ RELEVANT - Reloading messages...');
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
          '[ChatScreen] ✅ MESSAGE LISTENER SETUP COMPLETE - Ready to receive messages');
      print('[ChatScreen] ═══════════════════════════════════════════');
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
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback to initials
                    },
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
                  radius: 18,
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
            icon: const Icon(Icons.call, color: AppColors.primaryTeal),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.primaryTeal),
            onPressed: () {},
          ),
          // Test button for debugging real-time messages
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryTeal),
            onSelected: (String choice) {
              if (choice == 'test_message') {
                _testMessageUpdate();
              } else if (choice == 'debug_firebase') {
                _showFirebaseDebugInfo();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'test_message',
                child: Text('Test Update'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'debug_firebase',
                child: Text('🔥 Firebase Debug Info'),
              ),
            ],
          ),
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else {
      return '${dateTime.day}/${dateTime.month}';
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
