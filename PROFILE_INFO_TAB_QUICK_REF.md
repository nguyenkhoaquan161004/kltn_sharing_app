# ProfileInfoTab: Quick Reference Guide

## Overview
The ProfileInfoTab widget now supports two display modes:
1. **Own Profile** - Shows user's personal information
2. **Other User's Profile** - Shows their shared products

## Component Structure

```
ProfileInfoTab
├── Stats Row (horizontal layout)
│   ├── ProfileStats (productsShared, productsReceived)
│   └── Help Icon Button (scoring mechanism)
├── Own Profile Content (if isOwnProfile=true)
│   └── User Info Card
│       ├── Name
│       ├── Email
│       └── Address
└── Other User Content (if isOwnProfile=false)
    ├── Free Products Section (price=0)
    │   └── 2-Column Product Grid (max 3 items + "Xem thêm")
    └── Suggested Products Section (price>0)
        └── 2-Column Product Grid (max 3 items + "Xem thêm")
```

## Usage

### Display Own Profile Information
```dart
ProfileInfoTab(
  userData: {
    'name': 'Quan Nguyen',
    'email': 'quan@example.com',
    'address': '123 Main St',
    'productsShared': 63,
    'productsReceived': 12,
  },
  isOwnProfile: true,
  userId: 1, // Optional but recommended
)
```

### Display Other User's Profile
```dart
ProfileInfoTab(
  userData: {
    'name': 'Other User',
    'email': 'other@example.com',
    'address': 'Some Address',
    'productsShared': 10,
    'productsReceived': 5,
  },
  isOwnProfile: false,
  userId: 2, // Required for loading products
)
```

## Key Features

### 1. Horizontal Stats Layout
- **Stats Display**: Two columns showing productsShared and productsReceived
- **Scoring Button**: Icon-only button (help icon) aligned horizontally
- **Spacing**: 16px between stats and button, 32px below before content

### 2. Own Profile View
- **Title**: "Thông tin người dùng"
- **Fields**: Name, Email, Address
- **Edit Button**: Located in top-right of card
- **Styling**: White container with shadow, rounded corners

### 3. Other User Profile View
- **Section 1 - Free Products (0 đồng)**
  - Title: "Sản phẩm 0 đồng"
  - Shows products where price == 0
  - Grid: 2 columns, max 3 items shown
  - "Xem thêm" link if more than 3 items

- **Section 2 - Suggested Products**
  - Title: "Đề xuất cho bạn"
  - Shows products where price > 0
  - Grid: 2 columns, max 3 items shown
  - "Xem thêm" link if more than 3 items

### 4. Product Card Display
Each product shows:
- **Image**: Placeholder gray container (100px height)
- **Name**: Product name (max 2 lines, truncated with ellipsis)
- **Price**: Formatted as "0 đồng" (teal color) or "XXX VND"
- **Quantity**: "Còn X sản phẩm" (secondary text, smaller font)

## Data Requirements

### userData Map Fields
```dart
{
  'name': String,              // User's full name
  'email': String,             // User's email address
  'address': String,           // User's address
  'avatar': String,            // Avatar URL (not used in InfoTab)
  'points': int,               // Trust score (not used in InfoTab)
  'productsShared': int,       // Number of products shared
  'productsReceived': int,     // Number of products received
}
```

### userId Parameter
- **Type**: `int?` (optional)
- **Used for**: Filtering products from MockData for other user profiles
- **Required when**: `isOwnProfile = false`
- **Source**: Usually from route parameter `int.parse(widget.userId)`

## MockData Integration

The widget queries MockData for:

1. **Products List**
   ```dart
   MockData.items.where((item) => item.userId == userId).toList()
   ```

2. **Free Products Filter**
   ```dart
   userProducts.where((item) => item.price == 0).toList()
   ```

3. **Paid Products Filter**
   ```dart
   userProducts.where((item) => item.price > 0).toList()
   ```

## Styling & Colors

### Colors Used
- **Primary**: `AppColors.primaryTeal` (buttons, price)
- **Background**: `AppColors.backgroundWhite` (containers)
- **Placeholder**: `AppColors.backgroundGray` (image area)
- **Text Primary**: `AppColors.textPrimary` (main text)
- **Text Secondary**: `AppColors.textSecondary` (labels, hints)

### Dimensions
- **Container Padding**: 24 (outer), 20 (inner)
- **Border Radius**: 16 (containers), 10 (buttons), 12 (cards)
- **Spacing**: 16 (row items), 24 (between rows), 32 (section gap)
- **Icon Size**: 20 (help button), 32 (image placeholder)
- **Grid Spacing**: 12 (both axes)

## Interaction Points

### Scoring Mechanism Button
- **Location**: Top-right of stats row
- **Action**: Opens ScoringMechanismModal
- **Shows**: 5 scoring rules with points system

### "Xem thêm" Links
- **Location**: Top-right of each product section
- **Shows if**: More than 3 products available
- **Action**: TODO - Navigate to full product list view

### Edit Button (Own Profile Only)
- **Location**: Top-right of user info card
- **Action**: TODO - Navigate to edit profile screen

### Product Cards (Other Profile Only)
- **Tap Action**: TODO - Navigate to ProductDetailScreen
- **Currently**: Static display only

## Integration with Screens

### ProfileScreen (Own User)
```dart
ProfileInfoTab(
  userData: _userData,
  isOwnProfile: true,
  userId: 1, // Current user
)
```
- Located in Profile tab
- Shows personal information
- Shows statistics

### UserProfileScreen (Other Users)
```dart
ProfileInfoTab(
  userData: _userData,
  isOwnProfile: false,
  userId: int.parse(widget.userId), // From route param
)
```
- Located in user profile view
- Shows their shared products
- Shows statistics

## Responsive Behavior

### On Smaller Screens
- Column layout maintained
- GridView adapts to 2 columns
- Text truncates appropriately
- Containers maintain padding

### On Larger Screens
- Same layout (designed for mobile-first)
- Additional spacing not added
- Grid still 2 columns (consistent)

### Scroll Behavior
- SingleChildScrollView wraps entire content
- No scroll when content fits screen
- Smooth scroll when content exceeds height
- GridView uses `physics: NeverScrollableScrollPhysics`

## Common Customization

### Changing Grid Columns
Modify in `GridView.builder`:
```dart
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2, // Change to 3 or 4 for more columns
  ...
)
```

### Changing Max Items Per Section
Modify limit in `itemCount`:
```dart
itemCount: freeProducts.length > 3 ? 3 : freeProducts.length,
// Change 3 to desired number
```

### Changing Product Card Height
Modify `childAspectRatio`:
```dart
childAspectRatio: 0.75, // Decrease for taller cards, increase for shorter
```

### Hiding Sections
In `_buildOtherUserProfileContent()`:
```dart
if (freeProducts.isNotEmpty && showFreeProducts) ...[ // Add flag
  // Free products section
]
```

## Debugging Tips

### Print userId for verification
```dart
print('ProfileInfoTab userId: $userId');
print('Available products: ${MockData.items.length}');
```

### Check product filtering
```dart
print('User products: $userProducts');
print('Free products: $freeProducts');
```

### Verify userData contents
```dart
print('User data: $userData');
```

## Related Files

- **profile_stats.dart** - Stats display component
- **scoring_mechanism_modal.dart** - Scoring explanation modal
- **profile_info_tab.dart** - This widget (344 lines)
- **user_profile_screen.dart** - Other user profile screen
- **profile_screen.dart** - Own profile screen
- **mock_data.dart** - Product data source

## Version History

**v2.0** (Current)
- Restructured layout with horizontal stats + button
- Added conditional rendering for own vs other profiles
- Integrated product sections for other user profiles
- Added ProductCard display component
- 344 lines total

**v1.0** (Previous)
- Vertical layout with stats and button stacked
- Only personal info display
- 156 lines total

## Future Improvements

- [ ] Implement "Xem thêm" navigation for full product lists
- [ ] Add product card tap navigation to ProductDetailScreen
- [ ] Implement profile edit screen
- [ ] Load real product images from URLs
- [ ] Add product filtering and sorting options
- [ ] Support for pagination in product sections
- [ ] Cache product data for performance
- [ ] Add animations for section expansion
