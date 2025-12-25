import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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

  // Mock user data
  final Map<String, dynamic> user = {
    'id': 1,
    'name': 'Nguyễn Khoa Quân',
    'avatar': 'https://i.pravatar.cc/150?img=1',
    'isOnline': true,
  };

  // Mock messages
  late List<Map<String, dynamic>> messages = [
    {
      'id': 1,
      'sender': 'user',
      'content': 'Bạn ơi, sản phẩm này còn không?',
      'time': '10:30',
      'isSeen': true,
    },
    {
      'id': 2,
      'sender': 'other',
      'content': 'Còn đấy, bạn có quan tâm không?',
      'time': '10:32',
      'isSeen': true,
    },
    {
      'id': 3,
      'sender': 'user',
      'content': 'Có, tôi muốn hỏi về tình trạng của sản phẩm',
      'time': '10:33',
      'isSeen': true,
    },
    {
      'id': 4,
      'sender': 'other',
      'content': 'Sản phẩm như mới, chỉ sử dụng 2 lần',
      'time': '10:35',
      'isSeen': true,
    },
    {
      'id': 5,
      'sender': 'other',
      'content': 'Bạn có thể ghé lấy vào cuối tuần',
      'time': '10:35',
      'isSeen': true,
    },
    {
      'id': 6,
      'sender': 'user',
      'content': 'Oke, cảm ơn bạn nhé!',
      'time': '10:36',
      'isSeen': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
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

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final messageText = _messageController.text;
      setState(() {
        messages.add({
          'id': messages.length + 1,
          'sender': 'user',
          'content': messageText,
          'time':
              '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          'isSeen': false,
          'attachments': [], // Empty attachments by default
          'hasEmoji': _hasEmoji(messageText),
        });
      });
      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
    }
  }

  bool _hasEmoji(String text) {
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F9FF}]|[❤️👍✨]', unicode: true);
    return emojiRegex.hasMatch(text);
  }

  void _addImageAttachment(String filePath, String fileName) {
    setState(() {
      messages.add({
        'id': messages.length + 1,
        'sender': 'user',
        'content': '[Hình ảnh]',
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'isSeen': false,
        'attachments': [
          {
            'type': 'image',
            'url': filePath,
            'name': fileName,
            'isLocal': true,
          }
        ],
      });
    });
    _scrollToBottom();
  }

  void _addVideoAttachment(String filePath, String fileName) {
    setState(() {
      messages.add({
        'id': messages.length + 1,
        'sender': 'user',
        'content': '[Video]',
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'isSeen': false,
        'attachments': [
          {
            'type': 'video',
            'url': filePath,
            'name': fileName,
            'duration': '0:32',
            'isLocal': true,
          }
        ],
      });
    });
    _scrollToBottom();
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
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(user['avatar']),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  user['isOnline'] ? 'Đang hoạt động' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: user['isOnline'] ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
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
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMessage = message['sender'] == 'user';

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
                                ? AppColors.primaryTeal.withOpacity(0.2)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Text content
                              if (message['content'].toString().isNotEmpty &&
                                  !message['content']
                                      .toString()
                                      .startsWith('['))
                                Text(
                                  message['content'],
                                  style: AppTextStyles.bodySmall,
                                ),

                              // Attachments
                              if (message['attachments'] != null &&
                                  (message['attachments'] as List).isNotEmpty)
                                ...((message['attachments'] as List)
                                    .map((attachment) =>
                                        _buildAttachmentWidget(attachment))
                                    .toList()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              message['time'],
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (isUserMessage) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message['isSeen'] ? Icons.done_all : Icons.done,
                                size: 14,
                                color: message['isSeen']
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
}
