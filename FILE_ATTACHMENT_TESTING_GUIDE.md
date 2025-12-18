# File Attachment System - Testing Guide

## Quick Test Checklist

### 1. **File Picker Functionality**
- [ ] Open chat screen
- [ ] Tap attachment button (📎)
- [ ] Menu appears with Image, File, Video options
- [ ] Select "Chọn hình ảnh" → Gallery opens
- [ ] Select an image → Image appears in message input
- [ ] Select "Chọn file" → File browser opens with pdf/doc filters
- [ ] Select a file → File appears as attachment card
- [ ] Select "Chọn video" → Gallery opens with video filter
- [ ] Select a video → Video appears with play button overlay

### 2. **File Size Validation (50MB limit)**
Test with actual files:
- [ ] Select a file < 50MB → Should be added successfully
- [ ] Select a file > 50MB → Error snackbar: "[FileType] quá lớn (XX.X MB). Giới hạn là 50 MB."
- [ ] Create 55MB test file and try to select → Should show error
- [ ] Error message should dismiss automatically

### 3. **Emoji Picker**
- [ ] Tap emoji button in chat input
- [ ] Emoji grid appears above input bar (8 columns × 2 rows = 16 emojis)
- [ ] Tap any emoji → Emoji inserted into message text
- [ ] Picker automatically closes after emoji selection
- [ ] Tap emoji button again → Picker toggles closed
- [ ] Send message with emoji → Emoji appears in bubble

### 4. **Media Preview - Images**
- [ ] Send image attachment
- [ ] Tap image in chat → Full-screen preview opens
- [ ] Image displays with black background
- [ ] Pinch-to-zoom works (zoom 0.5x to 3x)
- [ ] Double-tap zooms in/out
- [ ] Tap back button or swipe back → Closes preview
- [ ] Download button visible in AppBar
- [ ] Filename shows in AppBar title

### 5. **Media Preview - Videos**
- [ ] Send video attachment
- [ ] Tap video in chat → Full-screen preview opens
- [ ] Video thumbnail displays with play button overlay
- [ ] Duration shows in bottom-right corner (e.g., "0:30")
- [ ] Tap back button → Closes preview
- [ ] Filename shows in AppBar title

### 6. **Download Dialog & System**
- [ ] Open media preview (image or video)
- [ ] Tap download button (📥)
- [ ] Dialog appears: "Bạn có muốn tải xuống file này không?"
- [ ] Tap "Hủy" → Dialog closes, no download
- [ ] Tap "Tải xuống" → Snackbar shows success message
- [ ] Try downloading a file attachment (non-media)
- [ ] Dialog appears before download
- [ ] Confirm dialog → Snackbar shows success

### 7. **Attachment Display in Chat**
- [ ] Image attachment:
  - Shows thumbnail (200x120px)
  - Tap to open preview
  - Shows in message bubble
- [ ] Video attachment:
  - Shows thumbnail with play button
  - Shows duration overlay
  - Tap to open preview
- [ ] File attachment:
  - Shows file icon (📄, 📊, 📝, etc.)
  - Shows filename and size (e.g., "document.pdf - 2.5 MB")
  - Tap to show download dialog

### 8. **Error Handling**
- [ ] Try sending oversized file (>50MB):
  - Error snackbar appears
  - File not added to message
  - User can select different file
- [ ] Try opening corrupted image:
  - Placeholder/empty gray area shown
  - No crash
- [ ] Network image URL error:
  - Gracefully handled with error builder

### 9. **Message Sending**
- [ ] Send message with emoji only → Message sent with emoji
- [ ] Send message with attachment → Message shows attachment + text
- [ ] Send empty message with attachment only → Only attachment sent
- [ ] Send multiple attachments in one message:
  - Add image → Add file → Add emoji
  - All appear in message
  - All sent together

### 10. **Local vs Network Files**
- [ ] Local file (just picked):
  - `isLocal: true`
  - Uses `Image.file()`
  - Shows properly as thumbnail
- [ ] Uploaded file (from previous session):
  - `isLocal: false`
  - Uses `Image.network()`
  - Shows properly as thumbnail

## Device-Specific Testing

### Android
1. Install app: `flutter run -d android`
2. Grant permissions:
   - Photos/Media
   - Files
   - Storage
3. Test file picker in system file browser
4. Verify 50MB validation works
5. Test downloading files to Downloads folder

### iOS
1. Install app: `flutter run -d ios`
2. Grant permissions:
   - Photo Library
   - Files
3. Test image/video picker
4. Verify file picker works
5. Test download functionality

## Manual File Size Testing

Create test files:
```bash
# Create 10MB file
dd if=/dev/zero of=test_10mb.bin bs=1M count=10

# Create 50MB file (edge case)
dd if=/dev/zero of=test_50mb.bin bs=1M count=50

# Create 55MB file (should fail)
dd if=/dev/zero of=test_55mb.bin bs=1M count=55
```

Then:
1. Try to send 10MB file → Should work ✅
2. Try to send 50MB file → Should work (edge case) ✅
3. Try to send 55MB file → Should show error ❌

## Debug Logging

To verify file operations are working:

```dart
// Add to chat_screen.dart in _getFileSize:
print('File path: $filePath');
print('File exists: ${file.existsSync()}');
print('File size bytes: ${file.statSync().size}');
print('File size MB: ${fileSizeInMB.toStringAsFixed(2)}');

// Add to _buildAttachmentWidget:
print('Building attachment: ${attachment['type']}, isLocal: $isLocal');
```

## Expected Behavior Summary

| Action | Expected Result | Status |
|--------|-----------------|--------|
| Select image < 50MB | Image added to message | ✅ Ready |
| Select file < 50MB | File card added | ✅ Ready |
| Select video < 50MB | Video thumbnail with play button | ✅ Ready |
| Select file > 50MB | Error snackbar shown | ✅ Ready |
| Tap emoji button | Grid appears above input | ✅ Ready |
| Select emoji | Emoji inserted in text | ✅ Ready |
| Tap image preview | Full-screen with zoom | ✅ Ready |
| Tap video preview | Full-screen with play overlay | ✅ Ready |
| Download media | Dialog shows before download | ✅ Ready |
| Send message | Attachments display with text | ✅ Ready |

## Known Limitations

1. **Download System**: Currently mocks downloads with snackbar
   - Actual file download needs backend integration
   - Ready for implementation

2. **Video Playback**: Preview is thumbnail only
   - Could add video player in future
   - Currently shows play button overlay

3. **Permissions**: May need manual configuration for:
   - Android: READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE
   - iOS: NSPhotoLibraryUsageDescription, NSPhotoLibraryAddOnlyUsageDescription

## Success Criteria

✅ All tests pass  
✅ No crashes on file operations  
✅ 50MB validation working  
✅ Emoji picker functional  
✅ Media preview with zoom  
✅ Download dialog system  
✅ Error handling graceful  
✅ Local file handling correct  
✅ UI responsive and smooth  
✅ Messages send successfully  

---
**Ready for Testing**: Yes ✅
**Build Status**: Compiles without errors ✅
**Dependencies**: All installed (flutter pub get) ✅
**Clean Build**: Completed (flutter clean) ✅
