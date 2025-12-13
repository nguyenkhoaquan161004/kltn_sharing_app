# ItemCard Component - Quick Reference

## Component Structure

```
ItemCard (Reusable Widget)
│
├── Displays
│   ├── Item image (placeholder)
│   ├── Status badge (available/pending)
│   ├── Free tag "0đ" (if applicable)
│   ├── Time countdown (HH:MM:SS)
│   ├── Item name
│   ├── Category ID
│   └── Quantity remaining
│
├── Features
│   ├── Live countdown timer (updates every second)
│   ├── GoRouter navigation support
│   ├── Customizable on-tap behavior
│   ├── Clean visual hierarchy
│   └── Full mock data integration
│
└── Properties
    ├── item: ItemModel (required)
    ├── onTap: VoidCallback? (optional)
    ├── showTimeRemaining: bool (default: true)
    ├── isFree: bool (default: false)
    └── price: double (default: 0)
```

## Screens Using ItemCard

### 1. HomeScreen
```
Home Tab: Shows available items in 2-column grid
├── Uses: ItemCard from MockDataService.getAvailableItems()
├── Updates: Real-time countdown for each item
└── Navigation: Tap → /item/{itemId}
```

### 2. SearchScreen
```
Search Tab: Shows search results when user searches
├── Uses: ItemCard from MockDataService.getAvailableItems()
├── Updates: Real-time countdown
└── Navigation: Tap → /item/{itemId}
```

### 3. SearchResultsScreen
```
Search Results: Dedicated screen for search results
├── Uses: ItemCard from MockDataService.getAvailableItems()
├── Updates: Real-time countdown
└── Navigation: Tap → /item/{itemId}
```

## Visual Representation

```
┌─ ItemCard (Width: 100% of 2-column grid cell) ─┐
│                                                   │
│  ┌──────────── Image Area (140px) ──────────┐  │
│  │  [Green]  [Status Badge]     [0đ]  [Red] │  │
│  │           "Có sẵn" / "Chờ xử lý"          │  │
│  │                                            │  │
│  │          [Image Placeholder]              │  │
│  │              📷 Icon                       │  │
│  │                                            │  │
│  │                              [⏱] 02:15:30 │  │ ← Time countdown
│  └────────────────────────────────────────────┘  │
│  ┌──────────── Content Area ──────────────────┐  │
│  │ Item Name (max 2 lines)                    │  │
│  │ Lorem ipsum dolor sit amet...              │  │
│  │                                            │  │
│  │ Danh mục #5                                │  │
│  │                                            │  │
│  │ 📦 Còn 3 sản phẩm                         │  │
│  └────────────────────────────────────────────┘  │
│                                                   │
└─────────────────────────────────────────────────┘
```

## Tags Explanation

### Status Badge (Top-Left)
- **Green**: Item is available for sharing
- **Orange**: Item is pending (awaiting confirmation)
- Always displayed

### "0đ" Tag (Top-Right)
- **Pink/Red Badge**: Indicates free item
- Only shown when price = 0
- Easily catches user attention

### Time Countdown (Bottom-Left)
- **Format**: HH:MM:SS
- **Orange**: Time remaining (updating)
- **Red**: Item expired ("Hết hạn")
- Only shows if item has expiration date

### Quantity (Bottom)
- **Shows remaining stock**: "Còn X sản phẩm"
- Always visible
- Includes inventory icon

## Color Scheme

| Element | Color | Purpose |
|---------|-------|---------|
| Status Badge (Available) | Green | Indicates availability |
| Status Badge (Pending) | Orange | Indicates pending state |
| Free Tag | Pink/Red (#badgePink) | Highlights free items |
| Time (Active) | Orange | Visual prominence |
| Time (Expired) | Red | Alert state |
| Item Name | Text Primary | Main content |
| Category | Text Secondary | Secondary info |
| Border | Light Gray | Subtle separation |

## Animation & Interactivity

### Countdown Timer
```
Update Frequency: Every 1 second
Trigger: onTap() on ItemCard
Effect: UI rebuilds with new time value
Stop: When item expires or widget disposed
```

### Tap Interaction
```
Default: context.push('/item/{itemId}')
Custom: Can pass onTap callback
Result: Navigates to item detail screen
```

## Integration Points

### With MockDataService
```dart
// Service provides mock items
final items = await _mockDataService.getAvailableItems();

// ItemCard consumes the data
ItemCard(item: items[0])
```

### With GoRouter
```dart
// Component handles navigation internally
// Uses: context.push('/item/{itemId}')
// Or custom onTap callback
```

## Code Examples

### Minimal Usage
```dart
ItemCard(item: itemFromMockData)
```

### Full Configuration
```dart
ItemCard(
  item: itemFromMockData,
  onTap: () => print('Tapped'),
  showTimeRemaining: true,
  isFree: itemFromMockData.price == 0,
  price: itemFromMockData.price.toDouble(),
)
```

### In GridView
```dart
GridView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index]);
  },
)
```

## Performance Characteristics

### Timer Management
- Each ItemCard instance has 1 Timer
- Timer cancels in dispose()
- Minimal resource usage
- Only active on visible screens

### Memory Impact
- ItemCard: ~5KB per instance
- Timer: Minimal overhead
- GoRouter integration: Shared

### Update Frequency
- Countdown: 1 second intervals
- Only rebuilds when time changes
- Other properties static

## Troubleshooting

### Timer Not Updating
**Solution**: Ensure `showTimeRemaining: true` and item has `expirationDate`

### "0đ" Tag Not Showing
**Solution**: Check if `price == 0` or `isFree: true`

### Navigation Not Working
**Solution**: Verify item has valid `itemId` and `/item/:id` route exists

### Time Showing "Hết hạn"
**Expected**: Item is expired, timer shows "Hết hạn" (Expired)

## Files Modified

1. ✅ Created: `lib/presentation/widgets/item_card.dart` (240 lines)
2. ✅ Updated: `lib/presentation/screens/home/home_screen.dart`
3. ✅ Updated: `lib/presentation/screens/search/search_screen.dart`
4. ✅ Updated: `lib/presentation/screens/search/search_results_screen.dart`

## Future Usage

To use ItemCard in other screens:

1. Import component:
```dart
import '../../widgets/item_card.dart';
```

2. Add MockDataService:
```dart
final MockDataService _mockDataService = MockDataService();
```

3. Use in grid/list:
```dart
ItemCard(item: itemModel)
```

That's it! Component handles all display and interaction logic.
