# Location Permission Request at App Startup

## Overview
Ứng dụng hiện đã được cấu hình để yêu cầu quyền truy cập vị trí ngay khi khởi động, trước khi đăng nhập. Điều này cho phép app lấy tọa độ (latitude, longitude) sớm để sử dụng trong các API call cần thông tin vị trí.

## Changes Made

### 1. Splash Screen (`lib/presentation/screens/splash/splash_screen.dart`)
- ✅ Thêm `LocationProvider` import và `Provider` package
- ✅ Thêm method `_requestLocationPermission()` để yêu cầu quyền truy cập vị trí
- ✅ Gọi `requestLocationPermissionAndGetLocation()` ngay trong `initState()`
- ✅ In log kết quả để debug: `[SplashScreen] Location permission result: {hasLocation}`

### 2. Location Service (`lib/data/services/location_service.dart`) - NEW
- ✅ Tạo singleton service để quản lý location toàn ứng dụng
- ✅ Có phương thức:
  - `getCurrentLocation()` - Lấy vị trí hiện tại từ device
  - `updateLocation(lat, lon)` - Cập nhật vị trí thủ công
  - Getter: `latitude`, `longitude`, `hasLocation`
- ✅ Tự động lưu location vào SharedPreferences

### 3. Main App (`lib/main.dart`)
- ✅ Thêm import `LocationService`
- ✅ Khởi tạo LocationService trong `main()` trước Firebase

### 4. iOS Configuration (`ios/Runner/Info.plist`)
- ✅ Thêm `NSLocationWhenInUseUsageDescription` - Yêu cầu vị trí khi đang dùng
- ✅ Thêm `NSLocationAlwaysAndWhenInUseUsageDescription` - Yêu cầu vị trí mọi lúc

### 5. Android Configuration (Already configured)
- ✅ `android/app/src/main/AndroidManifest.xml` đã có:
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.ACCESS_COARSE_LOCATION`
- ✅ `pubspec.yaml` đã có `geolocator: ^11.0.0`

## How to Use Location in API Calls

### Method 1: Sử dụng LocationProvider
```dart
import 'package:provider/provider.dart';
import 'data/providers/location_provider.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locationProvider = context.read<LocationProvider>();
    
    if (locationProvider.hasLocation) {
      final lat = locationProvider.latitude;
      final lon = locationProvider.longitude;
      
      // Call API with location
      itemService.searchNearby(latitude: lat, longitude: lon);
    }
  }
}
```

### Method 2: Sử dụng LocationService (Singleton)
```dart
import 'data/services/location_service.dart';

class MyApiService {
  Future<void> searchNearby() async {
    final locationService = LocationService();
    
    if (locationService.hasLocation) {
      final lat = locationService.latitude;
      final lon = locationService.longitude;
      
      // Use in API call
      final response = await _dio.get(
        '/api/v2/items/nearby',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
        },
      );
    }
  }
}
```

### Method 3: Watch location changes (UI Rebuild)
```dart
Consumer<LocationProvider>(
  builder: (context, locationProvider, child) {
    if (!locationProvider.hasLocation) {
      return Text('Đang lấy vị trí...');
    }
    
    return Text('Vị trí: ${locationProvider.latitude}, ${locationProvider.longitude}');
  },
)
```

## Flow Diagram

```
App Launch
    ↓
main() - Initialize LocationService
    ↓
SplashScreen - Request Location Permission
    ↓
User Grants/Denies Permission
    ↓
LocationProvider.requestLocationPermissionAndGetLocation()
    ↓
Get Current Position (lat, lon)
    ↓
Save to SharedPreferences
    ↓
Available for API calls throughout app
```

## Testing

### Android
1. Run: `flutter run`
2. Khi app khởi động, bạn sẽ thấy dialog yêu cầu quyền truy cập vị trí
3. Bấm "Allow" hoặc "Allow Only While Using The App"
4. Check logs: `[SplashScreen] Location permission result: true`

### iOS
1. Run: `flutter run`
2. Khi app khởi động, bạn sẽ thấy dialog yêu cầu quyền truy cập vị trí
3. Bấm "Allow While Using App"
4. Check logs: `[SplashScreen] Location permission result: true`

## Location Data Automatic Updates
- LocationProvider tự động cập nhật vị trí mỗi 7 phút (nếu user cấp quyền)
- Vị trí được lưu vào SharedPreferences tự động
- Có thể gọi `locationProvider.refreshLocation()` để cập nhật thủ công

## Error Handling
Các lỗi có thể xảy ra:
- Dịch vụ vị trí bị tắt → `errorMessage = 'Dịch vụ vị trí chưa được bật'`
- User từ chối quyền → `errorMessage = 'Quyền truy cập vị trí bị từ chối'`
- Từ chối vĩnh viễn → `errorMessage = 'Quyền truy cập vị trí bị từ chối vĩnh viễn...'`

Kiểm tra `locationProvider.errorMessage` để handle lỗi:
```dart
if (locationProvider.errorMessage != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(locationProvider.errorMessage!)),
  );
}
```
