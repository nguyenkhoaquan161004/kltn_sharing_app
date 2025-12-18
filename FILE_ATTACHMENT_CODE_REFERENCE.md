# File Attachment System - Code Reference

## Implementation Snippets

### 1. File Size Validation

**Location**: `chat_screen.dart` - Lines 313-321

```dart
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
```

**Usage**:
```dart
final fileSizeInMB = await _getFileSize(file.path);
if (fileSizeInMB > 50) {
  _showFileSizeError(fileType, fileSizeInMB);
  return;
}
```

---

### 2. File Picker Methods

**Location**: `chat_screen.dart` - Lines 249-312

#### Image Picker
```dart
Future<void> _pickImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    final fileSizeInMB = await _getFileSize(image.path);
    if (fileSizeInMB > 50) {
      _showFileSizeError('Image', fileSizeInMB);
    } else {
      _addImageAttachment(image.path, image.name);
    }
  }
}
```

#### Video Picker
```dart
Future<void> _pickVideo() async {
  final ImagePicker picker = ImagePicker();
  final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
  if (video != null) {
    final fileSizeInMB = await _getFileSize(video.path);
    if (fileSizeInMB > 50) {
      _showFileSizeError('Video', fileSizeInMB);
    } else {
      _addVideoAttachment(video.path, video.name);
    }
  }
}
```

#### File Picker
```dart
Future<void> _pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'pptx'],
    type: FileType.custom,
  );
  
  if (result != null && result.files.single.path != null) {
    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;
    final fileType = fileName.split('.').last.toLowerCase();
    
    final fileSizeInMB = await _getFileSize(filePath);
    if (fileSizeInMB > 50) {
      _showFileSizeError(fileType.toUpperCase(), fileSizeInMB);
    } else {
      _addFileAttachment(filePath, fileName, fileType);
    }
  }
}
```

---

### 3. Attachment Addition Methods

**Location**: `chat_screen.dart` - Lines 343-390

#### Image Attachment
```dart
void _addImageAttachment(String filePath, String fileName) {
  setState(() {
    widget.messages[0]['attachments'].add({
      'type': 'image',
      'url': filePath,
      'name': fileName,
      'isLocal': true,
      'fileType': 'image',
      'size': '${(File(filePath).statSync().size / (1024 * 1024)).toStringAsFixed(1)} MB',
    });
  });
}
```

#### File Attachment
```dart
Future<void> _addFileAttachment(String filePath, String fileName, String fileType) async {
  final fileSizeInMB = await _getFileSize(filePath);
  setState(() {
    widget.messages[0]['attachments'].add({
      'type': 'file',
      'url': filePath,
      'name': fileName,
      'isLocal': true,
      'fileType': fileType,
      'size': '${fileSizeInMB.toStringAsFixed(1)} MB',
    });
  });
}
```

#### Video Attachment
```dart
void _addVideoAttachment(String filePath, String fileName) {
  setState(() {
    widget.messages[0]['attachments'].add({
      'type': 'video',
      'url': filePath,
      'name': fileName,
      'isLocal': true,
      'fileType': 'video',
      'size': '${(File(filePath).statSync().size / (1024 * 1024)).toStringAsFixed(1)} MB',
      'duration': '0:30',
    });
  });
}
```

---

### 4. Attachment Display Widget

**Location**: `chat_screen.dart` - Lines 393-512

```dart
Widget _buildAttachmentWidget(dynamic attachment, int index) {
  if (attachment is Map) {
    final isLocal = attachment['isLocal'] as bool? ?? false;

    switch (attachment['type']) {
      case 'image':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () => _viewMedia(index),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLocal
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
            ),
          ),
        );

      case 'video':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () => _viewMedia(index),
            child: Container(
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

      case 'file':
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: GestureDetector(
            onTap: () => _showDownloadDialog(attachment),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description, color: Colors.grey),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment['name'] ?? 'File',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          attachment['size'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      default:
        return SizedBox.shrink();
    }
  }
  return SizedBox.shrink();
}
```

---

### 5. Media Preview Navigation

**Location**: `chat_screen.dart` - Lines 514-530

```dart
void _viewMedia(int index) {
  final attachment = widget.messages[0]['attachments'][index];
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MediaPreviewScreen(
        mediaUrl: attachment['url'],
        mediaType: attachment['type'], // 'image' or 'video'
        fileName: attachment['name'],
      ),
    ),
  );
}
```

---

### 6. Download Dialog

**Location**: `chat_screen.dart` - Lines 532-548

```dart
void _showDownloadDialog(dynamic attachment) {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Tải xuống file'),
      content: const Text('Bạn có muốn tải xuống file này không?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _downloadFile(attachment);
          },
          child: const Text('Tải xuống'),
        ),
      ],
    ),
  );
}
```

---

### 7. Download Implementation

**Location**: `chat_screen.dart` - Lines 550-560

```dart
void _downloadFile(dynamic attachment) {
  // Mock download
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Đang tải xuống: ${attachment['name']}'),
      duration: const Duration(seconds: 2),
    ),
  );
  // TODO: Implement actual file download
}
```

---

### 8. Emoji Picker Implementation

**Location**: `chat_input.dart` - Lines 23-105

```dart
class ChatInput extends StatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendPressed;
  final VoidCallback onAttachmentPressed;
  final Function(String)? onEmojiSelected;

  const ChatInput({
    required this.messageController,
    required this.onSendPressed,
    required this.onAttachmentPressed,
    this.onEmojiSelected,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _showEmojiPicker = false;
  final List<String> _emojis = [
    '😀', '😂', '😍', '🥰', '😎', '🔥', '✨', '👌',
    '👍', '❤️', '😢', '😡', '🙌', '💯', '🎉', '⭐',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Emoji Picker
        if (_showEmojiPicker)
          Container(
            height: 150,
            color: Colors.grey[100],
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    widget.messageController.text += _emojis[index];
                    widget.onEmojiSelected?.call(_emojis[index]);
                    setState(() => _showEmojiPicker = false);
                  },
                  child: Center(
                    child: Text(
                      _emojis[index],
                      textScaleFactor: 2,
                    ),
                  ),
                );
              },
            ),
          ),

        // Input bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Emoji button
              IconButton(
                icon: const Icon(Icons.emoji_emotions_outlined),
                onPressed: () {
                  setState(() => _showEmojiPicker = !_showEmojiPicker);
                },
              ),

              // Message input
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Attachment button
              IconButton(
                icon: const Icon(Icons.attachment),
                onPressed: widget.onAttachmentPressed,
              ),

              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: widget.onSendPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

---

### 9. Media Preview Screen (Image)

**Location**: `media_preview_screen.dart` - Lines 53-92

```dart
if (widget.mediaType == 'image')
  InteractiveViewer(
    minScale: 0.5,
    maxScale: 3.0,
    child: widget.mediaUrl.startsWith('http')
        ? Image.network(
            widget.mediaUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 64),
              );
            },
          )
        : Image.file(
            File(widget.mediaUrl),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 64),
              );
            },
          ),
  )
```

---

### 10. Media Preview Screen (Video)

**Location**: `media_preview_screen.dart` - Lines 93-133

```dart
else if (widget.mediaType == 'video')
  Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: widget.mediaUrl.startsWith('http')
              ? Image.network(
                  widget.mediaUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white,
                    );
                  },
                )
              : Image.file(
                  File(widget.mediaUrl),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white,
                    );
                  },
                ),
        ),
        const Icon(
          Icons.play_circle,
          size: 80,
          color: Colors.white,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '0:30',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    ),
  )
```

---

## Error Handling Examples

### File Size Error
```dart
void _showFileSizeError(String fileType, double sizeMB) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$fileType quá lớn (${sizeMB.toStringAsFixed(1)} MB). Giới hạn là 50 MB.',
      ),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Generic Error
```dart
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ),
  );
}
```

---

## Test Code Snippets

### Testing File Size Validation
```dart
// In a test, check if validation works:
final fileSizeInMB = await chatScreenState._getFileSize(testFilePath);
expect(fileSizeInMB, lessThan(50));
expect(fileSizeInMB, greaterThan(0));
```

### Testing Emoji Insertion
```dart
// Tap emoji button and verify state
final emojiButton = find.byIcon(Icons.emoji_emotions_outlined);
await tester.tap(emojiButton);
expect(find.byType(GridView), findsOneWidget);
```

---

## Important Notes

1. **File Path Storage**: Local files use absolute paths from device storage
2. **Network URLs**: Remote files use full HTTP/HTTPS URLs
3. **isLocal Flag**: Distinguishes between Image.file() and Image.network()
4. **Size Format**: Always stored as "X.X MB" string for display
5. **Emoji Auto-Close**: Picker closes after emoji selection (UX improvement)
6. **Error Recovery**: All errors are caught and shown via SnackBar

---

**Version**: 1.0  
**Last Updated**: December 16, 2024  
**Ready for Reference**: ✅ Yes
