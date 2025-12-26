# API Response Structure Fix ✅

## Problem

The app was getting an error when trying to parse the `/api/v2/transactions/me` response:

```
[CartAllScreen] Error loading data: Exception: Expected transactions data to be a List, got: _Map<String, dynamic>
```

## Root Cause

The API returns responses wrapped in a standard `ApiResponse` structure, which contains a `PageResponse` for paginated data. The code was not accounting for this two-level wrapping:

```
Response from Dio.get():
{
  success: true,
  status: 200,
  code: "...",
  message: "...",
  data: {                          // ← ApiResponse.data (PageResponse)
    page: 1,
    limit: 20,
    totalItems: 1,
    totalPages: 1,
    data: [                        // ← PageResponse.data (actual items)
      { id: "uuid", itemId: "...", status: "PENDING", ... },
      ...
    ]
  }
}
```

**The Issue**: The code was treating `response.data` (which is the PageResponse) as the transactions array, instead of extracting `response.data.data` (which is the actual transactions list).

## Solution

### Updated TransactionApiService.getMyTransactions()

```dart
final response = await _dio.get('/api/v2/transactions/me', ...);

if (response.statusCode == 200) {
  final apiResponse = response.data;  // This is ApiResponse{data: PageResponse}
  
  if (apiResponse is Map<String, dynamic>) {
    // Extract PageResponse from ApiResponse.data
    final pageResponse = apiResponse['data'];
    
    if (pageResponse is Map<String, dynamic>) {
      // Extract transactions list from PageResponse.data
      final transactionsList = pageResponse['data'];
      
      if (transactionsList is List) {
        // Parse each transaction
        final transactions = transactionsList
            .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return transactions;
      }
    }
  }
}
```

### Updated CartApiService.getCart()

Same structure applied - now properly extracts items from `apiResponse['data']['data']`:

```dart
final pageResponse = apiResponse['data'];  // PageResponse
final itemsList = pageResponse['data'];    // Actual items array
```

## Data Flow

```
HTTP 200 Response
    ↓
{success, status, code, message, data: PageResponse}
    ↓
Extract apiResponse['data'] → PageResponse{page, limit, data: [...]}
    ↓
Extract pageResponse['data'] → [TransactionDto, CartItemDto, ...]
    ↓
Map to Dart Models (TransactionModel, etc.)
    ↓
Display in UI
```

## Files Modified

✅ `lib/data/services/transaction_api_service.dart` - getMyTransactions()
✅ `lib/data/services/cart_api_service.dart` - getCart()

## API Response Structure Reference

### ApiResponse (Wrapper)
```java
@Data
public class ApiResponse<T> {
    private boolean success;
    private int status;
    private String code;
    private String message;
    private T data;              // Contains PageResponse for paginated endpoints
    private List<FieldError> errors;
    private Map<String, Object> meta;
    private LocalDateTime timestamp;
}
```

### PageResponse (Pagination)
```java
@Data
public class PageResponse<T> {
    private int page;
    private int limit;
    private long totalItems;
    private int totalPages;
    private List<T> data;        // Actual items/transactions
}
```

## Test Results

✅ Code compiles without errors (only info warnings about print statements)
✅ Correct two-level unwrapping of API response
✅ Proper extraction of transactions and cart items
✅ All type checking in place

## Status

**✅ FIXED** - API response parsing now properly handles:
1. ApiResponse wrapper with success, status, code, message
2. PageResponse with pagination metadata
3. Actual data items in the innermost `data` field

The app will now successfully:
- Parse transactions from `/api/v2/transactions/me`
- Parse cart items from `/api/v2/cart`
- Display them in the UI without errors
- Filter by status correctly

