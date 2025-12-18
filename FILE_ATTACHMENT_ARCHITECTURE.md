# File Attachment System - Visual Architecture

## User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHAT SCREEN                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Message Bubbles with Attachments                         │   │
│  │ • Images (200x120px thumbnails)                          │   │
│  │ • Videos (with play button overlay)                      │   │
│  │ • Files (with icon and size)                             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Chat Input Area                                          │   │
│  │ ┌────────────────────────────────────────────────────┐  │   │
│  │ │ [Emoji 😀] [Message Text Field] [Send]            │  │   │
│  │ │ [Attachment 📎]                                    │  │   │
│  │ └────────────────────────────────────────────────────┘  │   │
│  │                                                          │   │
│  │ IF Emoji Toggled:                                       │   │
│  │ ┌────────────────────────────────────────────────────┐  │   │
│  │ │ Emoji Grid (8 columns × 2 rows)                  │  │   │
│  │ │ 😀 😂 😍 🥰 😎 🔥 ✨ 👌                           │  │   │
│  │ │ 👍 ❤️  😢 😡 🙌 💯 🎉 ⭐                          │  │   │
│  │ └────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘

              ↓ Tap Attachment Button

┌──────────────────────────┐
│  Attachment Menu         │
│ ┌──────────────────────┐ │
│ │ Chọn hình ảnh      │ │ → Opens ImagePicker
│ ├──────────────────────┤ │
│ │ Chọn file          │ │ → Opens FilePicker (pdf/doc/etc)
│ ├──────────────────────┤ │
│ │ Chọn video         │ │ → Opens ImagePicker (video)
│ └──────────────────────┘ │
└──────────────────────────┘

              ↓ Select File

        File Size Check
        /            \
   < 50MB            > 50MB
    /                  \
  ✅                  ❌
Add to            Show Error
Message           SnackBar
  |
  ↓
┌─────────────────────────────────────┐
│ Attachment Card Added               │
│ ┌─────────────────────────────────┐ │
│ │ [Thumbnail]                     │ │
│ │ Filename: 2.5 MB                │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

              ↓ Tap Attachment

        Attachment Type Check
        /      |       \
    Image   Video    File
     /         |       \
    ↓         ↓        ↓
  Preview  Preview  Download
  Screen   Screen   Dialog
```

## Media Preview Flow

```
┌────────────────────────────────────┐
│   IMAGE PREVIEW SCREEN             │
├────────────────────────────────────┤
│ AppBar: [Back] Filename [Download] │
├────────────────────────────────────┤
│                                    │
│    [Full-screen Image]             │
│    • InteractiveViewer             │
│    • Pinch-to-zoom (0.5x - 3x)     │
│    • Pan/Move support              │
│                                    │
│    Black background                │
│                                    │
└────────────────────────────────────┘
         ↓
    Tap Download
         ↓
┌────────────────────────────────────┐
│   DOWNLOAD DIALOG                  │
├────────────────────────────────────┤
│ Bạn có muốn tải xuống file này?   │
│                                    │
│    [Hủy]    [Tải xuống]           │
└────────────────────────────────────┘
    ↙           ↘
  Cancel      Confirm
    ↓           ↓
  Close   Show Success
           SnackBar
```

```
┌────────────────────────────────────┐
│   VIDEO PREVIEW SCREEN             │
├────────────────────────────────────┤
│ AppBar: [Back] Filename [Download] │
├────────────────────────────────────┤
│                                    │
│    ┌──────────────────────┐       │
│    │  [Video Thumbnail]   │       │
│    │    ▶ (Play Button)   │       │
│    │  0:30 (Duration)     │       │
│    └──────────────────────┘       │
│                                    │
│    Black background                │
│                                    │
└────────────────────────────────────┘
         ↓
    Tap Download
         ↓
    Same Download Dialog
```

## File Size Validation Flow

```
User Selects File
       ↓
Get File Path
       ↓
Check File Exists
       ↓
Get File Size: file.statSync().size
       ↓
Convert to MB: size / (1024 * 1024)
       ↓
        ┌─── Is Size > 50MB? ───┐
        ↓                       ↓
      YES                      NO
       ↓                       ↓
  Show Error             Add to Message
  SnackBar               ✅ Success
  ❌ Fail
```

## Emoji Picker Implementation

```
Chat Input Widget (StatefulWidget)
│
├─ _showEmojiPicker: bool
│
├─ Emoji Button Click:
│  └─ setState(() => _showEmojiPicker = !_showEmojiPicker)
│
└─ If _showEmojiPicker is true:
   │
   ├─ Container with height animation
   │
   └─ GridView.builder
      ├─ GridDelegate: 8 columns
      ├─ itemCount: 16 emojis
      │
      └─ Each Emoji:
         ├─ GestureDetector on tap
         ├─ Insert to messageController.text
         ├─ setState(() => _showEmojiPicker = false)
         └─ Call onEmojiSelected callback
```

## Attachment Structure in Memory

```dart
// Message with attachments
{
  'id': 'msg_001',
  'sender_id': 'user_1',
  'text': 'Check these files!',
  'timestamp': '14:30',
  'attachments': [
    // Image Attachment
    {
      'type': 'image',
      'url': '/path/to/file.jpg',  // Local file path
      'name': 'photo.jpg',
      'isLocal': true,
      'size': '2.5 MB',
    },
    // Video Attachment
    {
      'type': 'video',
      'url': '/path/to/video.mp4', // Local file path
      'name': 'video.mp4',
      'isLocal': true,
      'duration': '0:45',
      'size': '45.2 MB',
    },
    // File Attachment
    {
      'type': 'file',
      'url': '/path/to/document.pdf', // Local file path
      'name': 'document.pdf',
      'isLocal': true,
      'fileType': 'pdf',
      'size': '1.2 MB',
    },
  ],
  'read': true,
}
```

## Widget Component Hierarchy

```
ChatScreen
├── Column
│   ├── Messages List (Expanded)
│   │   └── ListView
│   │       └── MessageBubble
│   │           └── (with Attachments)
│   │               ├── Image Attachment
│   │               │   └── GestureDetector → Preview
│   │               ├── Video Attachment
│   │               │   └── GestureDetector → Preview
│   │               └── File Attachment
│   │                   └── GestureDetector → Download
│   │
│   └── ChatInput (StatefulWidget)
│       ├── Emoji Button
│       ├── Emoji Picker (GridView)
│       │   └── 16 GestureDetectors for emojis
│       │
│       ├── Message TextField
│       ├── Attachment Button
│       │   └── Menu (Image/File/Video)
│       │
│       └── Send Button

MediaPreviewScreen (StatefulWidget)
├── Scaffold (Black background)
│   ├── AppBar
│   │   ├── Back Button
│   │   ├── Filename Text
│   │   └── Download Button
│   │
│   └── Body
│       └── Image Preview OR Video Preview
│           ├── InteractiveViewer (if image)
│           │   └── Image.file / Image.network
│           │
│           └── Stack (if video)
│               ├── Image thumbnail
│               ├── Play button overlay
│               └── Duration text
```

## Data Flow - File Selection to Display

```
1. User taps attachment button
   └─ _onAttachmentPressed() called
      └─ Shows menu dialog

2. User selects "Image" option
   └─ _pickImage() called
      ├─ Opens ImagePicker
      ├─ Gets file.path
      └─ _getFileSize(filePath)

3. File size validation
   ├─ Calculate: file.statSync().size / (1024 * 1024)
   ├─ If > 50MB:
   │  └─ _showFileSizeError()
   │     └─ Show SnackBar
   └─ If <= 50MB:
      └─ _addImageAttachment(filePath, fileName)

4. Attachment added to message
   ├─ Add to attachments array
   ├─ Set isLocal = true
   └─ Update UI (setState)

5. Attachment displayed
   ├─ _buildAttachmentWidget()
   ├─ Check isLocal flag
   ├─ Use Image.file() for local
   └─ Render thumbnail

6. User taps attachment
   ├─ _viewMedia() called
   ├─ Navigator.push() to MediaPreviewScreen
   └─ Full-screen preview opens

7. Download flow
   ├─ User taps download button
   ├─ _showDownloadDialog() called
   ├─ User confirms
   └─ _downloadFile() called
      └─ Show success SnackBar
```

## File Type Icons Mapping

```
PDF       → 📄
DOC       → 📝
DOCX      → 📝
XLS       → 📊
XLSX      → 📊
TXT       → 📋
PPTX      → 🎞️
JPG       → 🖼️
PNG       → 🖼️
MP4       → 🎬
MOV       → 🎬
```

## Error Handling Flow

```
File Operation
├─ File Picker Cancellation
│  └─ Silently ignored (user action)
│
├─ File Not Found
│  └─ _showError("File not found") → SnackBar
│
├─ File Too Large (> 50MB)
│  └─ _showFileSizeError() → Custom message
│
├─ Permission Denied
│  └─ _showError("Permission denied") → SnackBar
│
├─ Invalid File Type
│  └─ _showError("File type not supported") → SnackBar
│
└─ Unknown Error
   └─ _showError(error.toString()) → SnackBar
```

## Performance Considerations

- **Image Loading**: Uses `Image.file()` for local, cached with `Image.network()`
- **Video Thumbnail**: Pre-generated by OS (fast)
- **File Size**: Calculated once on selection, cached in attachment object
- **Emoji Grid**: GridView.builder (lazy loading, efficient)
- **Media Preview**: InteractiveViewer with lazy image loading

## Security Considerations

- File size limit prevents storage overflow (50MB max)
- File type validation prevents executable uploads
- Local file access via File() API (platform-safe)
- No sensitive data in logs
- Error messages don't expose system paths

---
**Architecture Version**: 1.0  
**Last Updated**: December 16, 2024  
**Implementation Status**: ✅ COMPLETE
