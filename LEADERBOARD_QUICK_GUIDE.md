# Leaderboard Integration - Quick Guide

## What's New

### Leaderboard now has 2 tabs:
1. **Thế giới (Global)** - Worldwide leaderboard
2. **Gần đây (Nearby)** - Leaderboard by location

## How It Works

### Global Tab
- Shows top users worldwide by total points
- Displays podium (top 3)
- Full leaderboard table sorted by rank
- No location required

### Nearby Tab
- Shows users within 50km of your location
- **Automatically converts your address to coordinates**
- Displays distance from each user
- Requires user to have address set in profile

## Key Features

✅ Auto-location detection from user address  
✅ Nominatim API for geocoding  
✅ Backend filtering by distance  
✅ Current user ranking in both tabs  
✅ Error handling for missing address  

## Files Modified

1. **gamification_api_service.dart**
   - New method: `getLeaderboardWithScope()`
   - Supports GLOBAL and NEARBY scopes

2. **gamification_provider.dart**
   - New method: `loadLeaderboardWithScope()`
   - Handles state for both leaderboard types

3. **gamification_response_model.dart**
   - New DTO: `LeaderboardEntryDto`
   - New DTO: `NewLeaderboardResponse`

4. **leaderboard_screen.dart**
   - Auto-loads nearby leaderboard on init
   - Converts address → coordinates
   - Handles missing address gracefully

## Usage

### For Developers

**Load Global Leaderboard:**
```dart
await gamificationProvider.loadLeaderboard(
  page: 0, 
  size: 20
);
```

**Load Nearby Leaderboard:**
```dart
await gamificationProvider.loadLeaderboardWithScope(
  scope: 'NEARBY',
  currentUserLat: 10.7769,
  currentUserLon: 106.6869,
  radiusKm: 50.0,
  page: 0,
  size: 20,
);
```

### For Users

1. **Make sure address is set** in your profile
2. Open Leaderboard screen
3. Switch between tabs to see global vs nearby rankings
4. Check distance info in Nearby tab

## API Endpoints

**New Endpoint:**
```
GET /api/v2/gamification/leaderboard
?scope=GLOBAL|NEARBY
&timeFrame=ALL_TIME|MONTHLY|WEEKLY
&page=0
&size=20
&currentUserLat=10.77
&currentUserLon=106.68
&radiusKm=50
```

## Error Messages

| Situation | Message |
|-----------|---------|
| Address not set | Skips nearby leaderboard (logged) |
| Address invalid | "Could not find coordinates" |
| API error | Shows in errorMessage |
| Network timeout | "Máy chủ không phản hồi" |

## Testing

### Quick Test
1. Login with account
2. Set address in profile (if not set)
3. Open Leaderboard
4. Should auto-load both global and nearby
5. Check console logs for debug info

### Manual Test
```
[Leaderboard] Converting address to coordinates: 123 Tran Duy Hung
[Leaderboard] Found coordinates - lat: 10.77, lon: 106.68
[GamificationAPI] Fetching leaderboard with scope=NEARBY
```

## Common Issues

### Nearby tab shows no users
- Check user has address in profile
- Check console logs for geocoding errors
- Try setting address again

### Coordinates not found
- Address format might not match OpenStreetMap
- Try using more specific address
- Check if address is in Vietnam

### API returns 401/403
- Token might be expired
- Re-login
- Check if bearer token is sent

## Configuration

### Default Settings
- Radius: 50 km
- Time Frame: ALL_TIME
- Page Size: 20
- Scope: GLOBAL for first tab, NEARBY for second

### Can be Customized
- Radius (radiusKm parameter)
- Time frame (ALL_TIME, MONTHLY, WEEKLY)
- Page size (up to 100)

## Performance Tips

- Leaderboard is loaded once on screen open
- Use pagination for large lists
- Cache results for 5-10 minutes if needed
- Address conversion happens async (doesn't block UI)

## Code Locations

| Feature | File |
|---------|------|
| API calls | `gamification_api_service.dart` |
| State management | `gamification_provider.dart` |
| Models | `gamification_response_model.dart` |
| UI | `leaderboard_screen.dart` |
| Geocoding | `address_service.dart` |

## Next Steps

- [ ] Add time frame selector UI (ALL_TIME, MONTHLY, WEEKLY)
- [ ] Add customizable radius UI
- [ ] Cache leaderboard data
- [ ] Add share score feature
- [ ] Add badges display
- [ ] Add level progress indicator
