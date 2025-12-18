import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/bottom_navigation_widget.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  // Mock messages data
  final List<Map<String, dynamic>> messages = [
    {
      'id': 1,
      'name': 'Nguyễn Khoa Quân',
      'lastMessage': 'Cảm ơn bạn đã chia sẻ!',
      'time': '2 phút trước',
      'unread': true,
      'avatar': 'https://i.pravatar.cc/150?img=1',
    },
    {
      'id': 2,
      'name': 'Trần Thị Mai',
      'lastMessage': 'Sản phẩm này còn không?',
      'time': '1 giờ trước',
      'unread': false,
      'avatar': 'https://i.pravatar.cc/150?img=2',
    },
    {
      'id': 3,
      'name': 'Lê Minh Phú',
      'lastMessage': 'Mình sẽ ghé lấy vào ngày mai',
      'time': '3 giờ trước',
      'unread': false,
      'avatar': 'https://i.pravatar.cc/150?img=3',
    },
    {
      'id': 4,
      'name': 'Phạm Quỳnh Anh',
      'lastMessage': 'Cảm ơn bạn!',
      'time': 'Hôm qua',
      'unread': false,
      'avatar': 'https://i.pravatar.cc/150?img=4',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: const AppHeaderBar(orderCount: 8),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return _buildMessageItem(context, message);
        },
      ),
      bottomNavigationBar: const BottomNavigationWidget(currentIndex: 0),
    );
  }

  Widget _buildMessageItem(BuildContext context, Map<String, dynamic> message) {
    return GestureDetector(
      onTap: () {
        // Navigate to chat screen
        context.push('/chat/${message['id']}');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          color: message['unread'] ? Colors.grey[50] : Colors.white,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(message['avatar']),
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
                      Text(
                        message['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: message['unread']
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        message['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: message['unread']
                          ? AppColors.textPrimary
                          : Colors.grey[600],
                      fontWeight:
                          message['unread'] ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Unread indicator
            if (message['unread'])
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
