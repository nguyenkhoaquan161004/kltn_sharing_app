# ProfileInfoTab Layout Restructuring

## Summary
Restructured the ProfileInfoTab widget to support dual-mode display:
- **Own profile (isOwnProfile=true)**: Shows user personal information
- **Other user's profile (isOwnProfile=false)**: Shows their shared products in two sections

## Changes Made

### 1. ProfileInfoTab Widget (`lib/presentation/screens/profile/widgets/profile_info_tab.dart`)

**Layout Changes:**
- **Before**: Stats displayed vertically with scoring button below in full width
- **After**: Stats and scoring button aligned horizontally
  - Stats takes `Flex: 2` width (left side)
  - Scoring button as icon button (right side)
  - Both share same vertical alignment

**Conditional Content Structure:**
```
Row {
  Expanded(flex: 2) { ProfileStats }
  SizedBox(width: 50) { Help Icon Button }
}
SizedBox(height: 32) // Spacing
if (isOwnProfile) {
  _buildOwnProfileContent() // Personal info card
} else {
  _buildOtherUserProfileContent() // Product sections
}
```

**New Methods Added:**

1. **`_buildOwnProfileContent()`**
   - Shows "Thông tin người dùng" section
   - Displays: Name, Email, Address
   - Edit button for own profile
   - Uses existing `_buildInfoRow()` helper

2. **`_buildOtherUserProfileContent()`**
   - Filters user's products from MockData
   - Splits into two categories:
     - **Free products (price == 0)**: "Sản phẩm 0 đồng"
     - **Paid products (price > 0)**: "Đề xuất cho bạn"
   - Each section:
     - Shows title with "Xem thêm" link if more than 3 items
     - Displays products in 2-column GridView
     - Shows only first 3 products per section
   - Empty state if user has no products

3. **`_buildProductCard(dynamic product)`**
   - Displays individual product with:
     - Product image placeholder (gray container with icon)
     - Product name (2 lines max)
     - Price (0 đồng or VND format)
     - Quantity remaining
   - Styled container with shadow

**Constructor Updates:**
- Added optional `userId` parameter (required for filtering products of other users)
- Signature: `ProfileInfoTab({userData, isOwnProfile, userId})`

### 2. UserProfileScreen Updates
**File**: `lib/presentation/screens/profile/user_profile_screen.dart`

- Now passes `userId` parameter to ProfileInfoTab:
  ```dart
  ProfileInfoTab(
    userData: _userData,
    isOwnProfile: false,
    userId: int.parse(widget.userId),
  )
  ```

### 3. ProfileScreen Updates  
**File**: `lib/presentation/screens/profile/profile_screen.dart`

- Added `userId: 1` for own profile tab to support conditional rendering:
  ```dart
  ProfileInfoTab(
    userData: _userData,
    isOwnProfile: widget.isOwnProfile,
    userId: 1, // Current user ID
  )
  ```

## UI Behavior

### Own Profile View
```
[Stats Row with Help Button] ← Horizontal alignment
┌─────────────────────────────────┐
│ Thông tin người dùng        [✎] │
├─────────────────────────────────┤
│ Tên người dùng: Quan Nguyen     │
│ Email: quan123@gmail.com        │
│ Địa chỉ: 8A/12A Thái Văn...    │
└─────────────────────────────────┘
```

### Other User Profile View
```
[Stats Row with Help Button] ← Horizontal alignment

Sản phẩm 0 đồng                  Xem thêm
[Product Grid - 2 columns, max 3 items]

Đề xuất cho bạn                  Xem thêm
[Product Grid - 2 columns, max 3 items]
```

## Data Integration

### MockData Usage
- `MockData.items.where((item) => item.userId == userId)` - Get user's products
- Filters by `price == 0` for free products section
- Filters by `price > 0` for suggested products section
- Displays up to 3 products per section in grid

### Product Information Displayed
- Product name
- Price (formatted as "0 đồng" or "XXX VND")
- Quantity remaining
- Default placeholder image

## Design Alignment
✅ Stats and scoring button positioned horizontally (as per requirement)
✅ Conditional content display based on profile type
✅ Product sections with 2-column grid layout
✅ "Xem thêm" links for expandable sections
✅ Proper spacing and visual hierarchy

## Testing Scenarios

1. **View own profile**:
   - Navigate to Profile tab
   - Should see personal info card with name, email, address
   - Scoring help button appears in stats row

2. **View other user's profile**:
   - Click on user from leaderboard or profile link
   - Should see "Sản phẩm 0 đồng" section (if user has free items)
   - Should see "Đề xuất cho bạn" section (if user has paid items)
   - Personal info should NOT appear
   - Stats and help button still visible

3. **Product sections**:
   - Grid displays 2 columns
   - Shows up to 3 items per section
   - Shows "Xem thêm" if more than 3 items
   - Each card shows price in teal color
   - Empty state message if user has no products

## Future Enhancements

TODO items marked in code:
- `// TODO: View all free products` - Implement view all page
- `// TODO: View all suggested products` - Implement view all page
- `// TODO: Navigate to edit profile` - Implement profile edit
- Product cards could link to ProductDetailScreen on tap
- Load real images instead of placeholder icons

## Code Quality

✅ No compilation errors
✅ No type safety issues
✅ Proper null handling with `??` operator
✅ Responsive grid layout
✅ Clean separation of concerns with helper methods
✅ Follows Flutter naming conventions
✅ Uses MockData for realistic data
