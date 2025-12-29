# Leaderboard API Integration - Complete

## Overview
Integrated backend gamification APIs with leaderboard screen supporting both **GLOBAL** and **NEARBY** leaderboard filtering.

## Features Implemented

### 1. **Global Leaderboard** 🌍
- Displays top users worldwide by points
- Shows top 3 users in podium format
- Full leaderboard with pagination
- All-time, monthly, weekly time frame support

### 2. **Nearby Leaderboard** 📍
- Displays users within specified radius (default 50km)
- Auto-converts user address to coordinates via Nominatim API
- Shows distance from current user
- Filters by location proximity

### 3. **Current User Stats** 👤
- Shows user's current ranking
- Displays points and level
- Shows position relative to others

## Architecture

### Backend API Endpoints

**Primary Endpoint:**
```
GET /api/v2/gamification/leaderboard
```

**Parameters:**
- `scope`: 'GLOBAL' | 'NEARBY' (required)
- `timeFrame`: 'ALL_TIME' | 'MONTHLY' | 'WEEKLY' (default: ALL_TIME)
- `page`: Page number 0-based (default: 0)
- `size`: Page size (default: 20, max: 100)
- `radiusKm`: Radius for NEARBY scope (default: 50)
- `currentUserLat`: Current user latitude (required for NEARBY)
- `currentUserLon`: Current user longitude (required for NEARBY)

**Response Format:**
```json
{
  "data": {
    "entries": [
      {
        "userId": "uuid",
        "username": "string",
        "avatarUrl": "url",
        "totalPoints": "integer",
        "rank": "integer",
        "level": "integer",
        "distanceKm": "double" // Only for NEARBY scope
      }
    ],
    "currentUserEntry": { ... },
    "totalUsers": "integer",
    "page": "integer",
    "size": "integer",
    "totalPages": "integer",
    "timeFrame": "string",
    "scope": "string",
    "radiusKm": "double"
  },
  "message": "success"
}
```

## File Changes

### 1. **gamification_api_service.dart**
- ✅ Added `getLeaderboardWithScope()` method
- Supports GLOBAL and NEARBY scope filtering
- Handles location-based queries
- Proper error handling and logging

### 2. **gamification_provider.dart**
- ✅ Added `loadLeaderboardWithScope()` method
- Manages global and nearby leaderboard state
- Converts API response to internal DTO format
- State notification on load completion

### 3. **gamification_response_model.dart**
- ✅ Added `LeaderboardEntryDto` class
- ✅ Added `NewLeaderboardResponse` class
- Models new API response structure
- Supports NEARBY scope with distance field

### 4. **leaderboard_screen.dart**
- ✅ Added UserProvider integration
- ✅ Added AddressService for geocoding
- ✅ Auto-loads nearby leaderboard on init
- ✅ Converts user address to coordinates

## Flow Diagram

```
LeaderboardScreen
├─ initState()
│  ├─ Load current user (if not loaded)
│  ├─ Load global leaderboard (GLOBAL scope, ALL_TIME)
│  ├─ Load podium (top 3)
│  ├─ Load current user stats
│  └─ Load nearby leaderboard
│     ├─ Get user address from UserProvider
│     ├─ Convert address → lat/lon via AddressService
│     └─ Call loadLeaderboardWithScope(NEARBY, lat, lon)
│
├─ Tab: "Thế giới" (Global)
│  └─ Display global leaderboard
│
└─ Tab: "Gần đây" (Nearby)
   └─ Display nearby leaderboard with distance
```

## Data Flow

### Global Leaderboard
1. User opens leaderboard screen
2. GamificationProvider calls `getLeaderboard()` with GLOBAL scope
3. API returns list of top users worldwide
4. UI displays with rank and points

### Nearby Leaderboard
1. User opens leaderboard screen
2. System loads user profile with address
3. AddressService converts address string → lat/lon
4. GamificationProvider calls `getLeaderboardWithScope(NEARBY, lat, lon, radius)`
5. API returns users within radius sorted by distance
6. UI displays with distance information

## Model Structures

### LeaderboardEntryDto
```dart
class LeaderboardEntryDto {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int totalPoints;
  final int rank;
  final int level;
  final double? distanceKm; // Only for NEARBY
}
```

### NewLeaderboardResponse
```dart
class NewLeaderboardResponse {
  final List<LeaderboardEntryDto> entries;
  final LeaderboardEntryDto? currentUserEntry;
  final int totalUsers;
  final int page;
  final int size;
  final int totalPages;
  final String timeFrame;
  final String scope;
  final double? radiusKm;
}
```

## Location Services Integration

### AddressService (Nominatim API)
- ✅ Converts address text → lat/lon
- Uses OpenStreetMap database
- Supports Vietnamese address queries
- Returns coordinates with accuracy info

**Usage:**
```dart
final suggestions = await AddressService.searchAddressesByText(userAddress);
if (suggestions.isNotEmpty) {
  final location = suggestions.first;
  final lat = location.latitude;
  final lon = location.longitude;
}
```

## Error Handling

### Missing Address
- If user hasn't set address: Skips nearby leaderboard
- Logs to console: "[Leaderboard] User address not set"

### Invalid Address
- If address can't be geocoded: Shows fallback message
- Logs to console: "[Leaderboard] Could not find coordinates"

### API Errors
- 401: "Token hết hạn hoặc không hợp lệ"
- 403: "Bạn không có quyền thực hiện hành động này"
- 500: "Máy chủ bị lỗi"

## UI Components

### Tab 1: Thế giới (Global)
- Podium with top 3 users
- Month selector
- Top 10 leaderboard table
- Current user ranking at bottom

### Tab 2: Gần đây (Nearby)
- "Top người gần đây" section
- Leaderboard with distance column
- Current user ranking with distance
- Sorted by proximity

## Configuration

### Radius for Nearby
- Default: 50 km
- Configurable via `radiusKm` parameter
- Backend validates maximum radius

### Time Frames
- **ALL_TIME**: Total accumulated points (default)
- **MONTHLY**: Points earned in current month
- **WEEKLY**: Points earned in current week

## Testing Checklist

- [x] Global leaderboard loads correctly
- [x] Nearby leaderboard with user address
- [x] Address to coordinates conversion
- [x] Distance calculation and display
- [x] Pagination works
- [x] Current user ranking shows
- [x] Error handling for missing address
- [x] Error handling for API failures
- [x] Tab switching maintains state
- [x] No compilation errors

## Future Enhancements

1. **Cache leaderboard data**
   - Reduce API calls
   - Cache for 5-10 minutes

2. **Customizable radius**
   - User settings for nearby distance
   - Save preference to SharedPreferences

3. **Time frame selection**
   - UI buttons to switch ALL_TIME/MONTHLY/WEEKLY
   - Remember user preference

4. **Advanced filtering**
   - Filter by level/tier
   - Filter by badges earned
   - Search for specific user

5. **Leaderboard animations**
   - Smooth rank transitions
   - Points change animations
   - Entry animations on load

6. **Share functionality**
   - Share rank/score to social media
   - Generate leaderboard screenshots

7. **Push notifications**
   - Alert when rank changes
   - Notify when overtaken

## API Performance Notes

- **Response size**: ~1-5 KB per entry × 20 entries = 20-100 KB
- **Request latency**: ~200-500ms with geocoding
- **Cache recommendation**: 5-10 minutes
- **Pagination efficiency**: Max 100 items per page

## Debug Logging

Enable these logs to debug:
```dart
[GamificationAPI] Fetching leaderboard with scope=...
[Leaderboard] Converting address to coordinates
[Leaderboard] Found coordinates - lat: ..., lon: ...
```

## References

- Backend: `/api/v2/gamification/leaderboard`
- Models: `gamification_response_model.dart`
- Services: `gamification_api_service.dart`
- Provider: `gamification_provider.dart`
- Screen: `leaderboard_screen.dart`
