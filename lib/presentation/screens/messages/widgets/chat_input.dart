import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final Function(String emoji)? onEmojiSelected;
  final VoidCallback? onAttachmentPressed;

  const ChatInput({
    super.key,
    required this.messageController,
    required this.onSendMessage,
    this.onEmojiSelected,
    this.onAttachmentPressed,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmojiPicker = false;

  // Popular emojis
  final List<String> _emojis = [
    '😀',
    '😂',
    '😍',
    '🥰',
    '😎',
    '🤔',
    '😢',
    '😡',
    '👍',
    '❤️',
    '🔥',
    '✨',
    '👌',
    '🙌',
    '😍',
    '💯',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji picker (if visible)
        if (_showEmojiPicker)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.messageController.text += _emojis[index];
                    widget.onEmojiSelected?.call(_emojis[index]);
                    setState(() => _showEmojiPicker = false);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Chat input bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Emoji button
                IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.emoji_emotions
                        : Icons.emoji_emotions_outlined,
                  ),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                  },
                ),
                // Text input
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // Text field
                        Expanded(
                          child: TextField(
                            controller: widget.messageController,
                            decoration: InputDecoration(
                              hintText: 'Nhắn tin...',
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            maxLines: null,
                          ),
                        ),
                        // Attachment button
                        IconButton(
                          icon: const Icon(Icons.attach_file),
                          color: AppColors.textSecondary,
                          onPressed: widget.onAttachmentPressed,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // Send button
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: widget.onSendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
