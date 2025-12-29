# Type Cast Error Fix - String to Map<String, dynamic>

## Error Encountered
```
type 'String' is not a subtype of type 'Map<String, dynamic>?' in type cast
```

## Root Cause
When calling `_messageApiService.sendMessage()`, the response parsing was attempting to cast a String directly to `Map<String, dynamic>`, which causes a type mismatch.

Possible scenarios:
1. API returns response in unexpected format (data as String instead of Map)
2. Response parsing logic doesn't handle all possible response structures
3. Error message from backend returned as String instead of proper JSON

## Changes Made

### 1. **message_api_service.dart** - Enhanced Type Checking
```dart
// OLD: Unsafe cast
return MessageModel.fromJson(data as Map<String, dynamic>);

// NEW: Safe type checking + Map.from() conversion
if (data is! Map) {
  print('[MessageAPI] ERROR: data is not Map, got ${data.runtimeType}');
  throw Exception('Invalid response format: expected Map, got ${data.runtimeType}. Value: $data');
}

// Safe cast with Map.from() to ensure proper conversion
final dataMap = Map<String, dynamic>.from(data as Map);
return MessageModel.fromJson(dataMap);
```

**Added:**
- Type validation before casting: `data is! Map`
- Detailed error message showing actual type and value
- `Map.from()` for safe conversion to `Map<String, dynamic>`
- `rethrow` to propagate unexpected errors

### 2. **profile_products_tab.dart** - Better Error Logging
```dart
// OLD: Simple catch with print
} catch (e) {
  print('[ProfileProducts] Error sending notification: $e');
}

// NEW: Detailed error logging with stack trace
} catch (e, st) {
  print('[ProfileProducts] Error sending notification: $e');
  print('[ProfileProducts] Stack trace: $st');
  // Don't block the transaction if message sending fails
}
```

**Added:**
- Stack trace capture: `catch (e, st)`
- Service type logging: `_messageApiService.runtimeType`
- Message success logging with ID

## How to Debug Further

If error persists, check console output for:

1. **Response data type**: `[MessageAPI] Final data type before parsing: {type}, value: {value}`
2. **Actual response structure**: Look at `[MessageAPI] Response data:` line
3. **Stack trace**: Shows exact line where type cast fails

## Testing

Run app and trigger accept button:
```
flutter run
```

Monitor logs for:
- ✅ `[MessageAPI] REQUEST[POST]` - Request sent
- ✅ `[MessageAPI] SUCCESS[200]` - Response received
- ✅ `[MessageAPI] First level data type: {type}` - Parsing step 1
- ✅ `[MessageAPI] Final data type before parsing: Map` - Should be Map
- ✅ `[MessageAPI] Message sent successfully` - Success

## If Error Still Occurs

The error will now show:
```
Invalid response format: expected Map, got String. Value: {actual_value}
```

This means the backend is returning a different format. Possible fixes:
1. Check backend API response structure
2. Verify JWT token is valid (could return 401 error message)
3. Check if receiving a redirect response (302, 301)
4. Verify receiverId format matches backend expectations

## Prevention

- Always validate response type before casting
- Use `Map.from()` instead of direct `as Map<String, dynamic>`
- Log detailed error information with values
- Include stack traces for unexpected errors
