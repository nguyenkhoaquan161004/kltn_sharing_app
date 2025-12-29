# Requester Management Quick Guide

## What Changed?

### 1. Dynamic Requester List
When you open a product's detail sheet, requesters are now **cached and updated dynamically** instead of fetching every time.

**Before:**
- FutureBuilder reloaded requesters on every sheet open
- Slow and redundant API calls

**Now:**
- Requesters cached in `_requestersCache` Map
- StatefulBuilder allows live updates
- Faster, smoother UX

### 2. Remove Requester on Accept/Reject
When you accept or reject a requester:
- ✅ Requester **immediately removed** from list
- ✅ Sheet **updates** without closing
- ✅ Snackbar shows confirmation
- ✅ Products reload in background

**Before:**
- Had to close detail sheet
- Then reopen to see updated list

**Now:**
- Stays open, list updates in place
- Instant visual feedback

### 3. Auto-Save Recipient Info
When you **accept** a transaction:
- ✅ Recipient name, phone, address captured
- ✅ **Auto-appended** to product description
- ✅ Visible in product detail section
- ✅ Format: "Người nhận: [Name] - [Phone] - [Address]"

**Benefits:**
- No manual record keeping
- Recipient info always available
- Easy reference when contacting receiver

## Code Changes Summary

| File | Change | Impact |
|------|--------|--------|
| `profile_products_tab.dart` | FutureBuilder → StatefulBuilder | Dynamic updates |
| `profile_products_tab.dart` | Added `_requestersCache` | State caching |
| `profile_products_tab.dart` | Updated `_acceptRequest` | Description update |
| `profile_products_tab.dart` | Updated `_rejectRequest` | Remove from cache |
| `item_api_service.dart` | Added `updateItemDescription()` | API call for description |
| `transaction_model.dart` | Added `receiverPhone`, `receiverAddress` | Store recipient info |

## Usage Example

```dart
// 1. Detail sheet opens and loads requesters into cache
showModalBottomSheet(
  context: context,
  builder: (context) => _buildProductDetailSheet(product)
);

// 2. User taps Accept button
_acceptRequest(transaction, product, productId, onStatusChanged);

// 3. Behind the scenes:
// - Transaction accepted via API
// - Description updated: "Người nhận: John - 0912345678 - 123 Tran Duy Hung"
// - Requester removed from _requestersCache[productId]
// - onStatusChanged() calls setSheetState to refresh UI

// 4. Sheet updates automatically, requester disappears
// 5. Snackbar: "Đã chấp nhận yêu cầu từ John"
```

## Files to Review

1. **profile_products_tab.dart** - Main logic
   - Lines 824-878: `_buildProductDetailSheet()` refactor
   - Lines 1099-1247: `_acceptRequest()` with description update
   - Lines 1249-1317: `_rejectRequest()` with cache removal

2. **item_api_service.dart** - API integration
   - Lines 563-587: New `updateItemDescription()` method

3. **transaction_model.dart** - Data model
   - Lines 24-25: New receiver fields
   - Lines 43-44: Constructor additions
   - Lines 140-141: fromJson() parsing

## Potential Issues & Fixes

### Issue: Requester not removed from list
**Cause:** `_requestersCache` not initialized
**Fix:** Ensure `initState()` initializes the map

### Issue: Description update fails silently
**Cause:** API error not surfaced
**Fix:** Check backend logs, ensure itemId is valid UUID

### Issue: Sheet closes unexpectedly
**Cause:** Multiple Navigator.pop() calls
**Fix:** Use SchedulerBinding callback for safe pop

## Performance Notes

- Cache loaded **once per product per session**
- StatefulBuilder rebuilds **only when needed**
- Non-blocking description updates
- No blocking during API calls (non-UI threads)

## Testing Steps

1. **Open product detail**
   - Verify requesters load immediately
   - Check requester count displayed

2. **Accept request**
   - Verify requester removed from list
   - Check snackbar confirmation
   - Verify product description in backend

3. **Reject request**
   - Verify requester removed from list
   - Check snackbar confirmation
   - Verify product still available for others

4. **Accept multiple requesters**
   - Verify recipient info includes latest accept
   - No duplicate "Người nhận:" entries

## API Contract

### Update Item Description
```
PUT /api/v2/items/{itemId}
Content-Type: application/json

{
  "description": "Người nhận: John Doe - 0912345678 - 123 Tran Duy Hung\n\nOriginal description..."
}

Response: 200 OK or 204 No Content
```

## Next Steps

- [ ] Add edit button to change recipient info
- [ ] Show recipient info in product card view
- [ ] Add transaction history view
- [ ] Implement bulk accept/reject
- [ ] Add recipient acceptance notification in home tab
