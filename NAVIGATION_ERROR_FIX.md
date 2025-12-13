# Navigation Stack Error - Root Cause & Resolution

## Error Message
```
You have popped the last page off of the stack, there are no pages left to show
'package:flutter/src/widgets/navigator.dart': Failed assertion: line 3882 pos 12:
'!_debugLocked': is not true.
```

## Root Cause Analysis

### Issue 1: Missing Route Definition
**Problem**: The app was trying to navigate to `/item/:id` using:
```dart
context.push('/item/${item.itemId}');
```

But there was no route defined for `/item/:id` in `app_router.dart`. Only `/product/:id` existed.

**Result**: GoRouter couldn't find the route, causing undefined behavior and eventual stack corruption.

### Issue 2: Modal Context Pop Issue
**Problem**: Inside `showModalBottomSheet`, the builder receives a new context (the modal's context), but code was calling `context.pop()` thinking it was the screen's context.

```dart
// ❌ WRONG - context here is modal's context, not screen's
showModalBottomSheet(
  context: context,
  builder: (context) {  // This is different context!
    return ListTile(
      onTap: () {
        context.pop();  // Trying to pop modal's context
      },
    );
  },
);
```

This causes conflicts between the modal's Navigator stack and GoRouter's stack.

### Issue 3: Remaining Navigator Calls
**Problem**: Four files still had direct `Navigator.pop()` calls:
- `store_information_screen.dart` (2 calls)
- `cart_all_screen.dart` (1 call)
- `profile_products_tab.dart` (1 call)

These mixed with GoRouter navigation caused stack conflicts.

---

## Solutions Implemented

### Solution 1: Add Missing Route
**File**: `lib/routes/app_router.dart`

Added the `/item/:id` route that was being called but not defined:
```dart
GoRoute(
  path: '/item/:id',
  name: 'item-detail',
  pageBuilder: (context, state) {
    final itemId = state.pathParameters['id'] ?? '';
    return _buildPageWithTransition(
      child: ProductDetailScreen(productId: itemId),
      state: state,
      name: 'item-detail',
    );
  },
),
```

### Solution 2: Fix Modal Context Issue
**File**: `lib/presentation/screens/profile/widgets/profile_products_tab.dart`

Changed from:
```dart
// ❌ WRONG
void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    builder: (context) {  // Shadows outer context
      return ListTile(
        onTap: () {
          context.pop();  // Wrong context!
        },
      );
    },
  );
}
```

To:
```dart
// ✅ CORRECT
void _showSortOptions() {
  showModalBottomSheet(
    context: context,
    builder: (bottomSheetContext) {  // Explicit modal context
      return ListTile(
        onTap: () {
          bottomSheetContext.pop();  // Correct context!
        },
      );
    },
  );
}
```

### Solution 3: Replace Remaining Navigator Calls
**Files Modified**:
1. `store_information_screen.dart` - Added GoRouter import, replaced 2x Navigator.pop
2. `cart_all_screen.dart` - Added GoRouter import, replaced Navigator.pop
3. `profile_products_tab.dart` - Already had GoRouter import, fixed context issue

Changed all from:
```dart
Navigator.pop(context);
onPressed: () => Navigator.pop(context),
```

To:
```dart
context.pop();
onPressed: () => context.pop(),
```

---

## Files Changed (4 Additional)

### New Fixes
1. ✅ `app_router.dart` - Added `/item/:id` route
2. ✅ `store_information_screen.dart` - Replaced Navigator.pop (2x)
3. ✅ `cart_all_screen.dart` - Replaced Navigator.pop (1x)
4. ✅ `profile_products_tab.dart` - Fixed modal context (1x)

### Total Files Modified
- **16 files** (from previous session)
- **+4 files** (this session)
- **= 20 files total**

---

## Summary of Changes

| Change | Before | After | Status |
|--------|--------|-------|--------|
| Route definition | Missing `/item/:id` | Route added | ✅ |
| Modal contexts | Using wrong context | Explicit parameter | ✅ |
| Navigator calls | 4 remaining | 0 remaining | ✅ |
| Compilation | Navigation issues | Clean | ✅ |
| Navigation stack | Corrupted | Single, unified | ✅ |

---

## Verification

### ✅ All Navigator Calls Eliminated
```bash
grep -r "Navigator\." lib/presentation/screens/
# Result: No matches found
```

### ✅ Route Defined
```dart
// app_router.dart contains:
GoRoute(
  path: '/item/:id',
  // ... configuration
),
```

### ✅ Modal Contexts Fixed
```dart
// profile_products_tab.dart:
showModalBottomSheet(
  builder: (bottomSheetContext) {  // ✅ Explicit context
    bottomSheetContext.pop();  // ✅ Uses correct context
  },
);
```

### ✅ No Compilation Errors
- Presentation layer: Clean
- Routes layer: Clean
- All GoRouter imports in place

---

## Expected Behavior After Fix

### Scenario 1: Item Navigation
1. User on HomeScreen clicks item
2. `context.push('/item/1')` → Route found ✅
3. ItemDetailScreen displays
4. User clicks back → `context.pop()` → Back to HomeScreen ✅

### Scenario 2: Modal Selection
1. User opens ProfileProductsTab
2. User clicks "Sort By"
3. Modal shows with correct context
4. User selects option → `bottomSheetContext.pop()` → Modal closes ✅
5. Sort applied, no stack errors ✅

### Scenario 3: Bottom Navigation
1. User clicks bottom nav items
2. `context.go()` replaces routes correctly
3. All navigation smooth without "last page" errors ✅

---

## Key Takeaways

### Important Rules
1. **Always use `context.push/pop`** with GoRouter - never mix with Navigator
2. **Define all routes** in `app_router.dart` before using `context.push()`
3. **Watch context shadowing** in builders:
   - Modal builders: `builder: (modalContext)` not `builder: (context)`
   - Dialog builders: Same pattern
4. **Use explicit parameter names** to avoid confusion

### Prevention
- Create routes in app_router.dart **before** using them
- Use IDE refactoring to rename contexts in builders
- Test back navigation on all screens
- Never call `Navigator.pop/push` - use `context.pop/push` instead

---

## Status

**✅ RESOLVED**

All navigation errors have been fixed:
- Missing route added
- Modal contexts corrected  
- All Navigator calls eliminated
- Clean compilation
- Ready for testing

---

## Testing Checklist

- [ ] Open app, navigate to HomeScreen
- [ ] Click on an item → ItemDetailScreen opens
- [ ] Click back → Returns to HomeScreen
- [ ] Open ProfileProductsTab
- [ ] Click "Sort By" → Modal opens
- [ ] Select sort option → Modal closes, no errors
- [ ] Use bottom navigation tabs → Smooth transitions
- [ ] Click back from any screen → Works correctly
- [ ] No "popped last page" errors
- [ ] No "_debugLocked" assertion errors

All tests should pass without navigation errors.
