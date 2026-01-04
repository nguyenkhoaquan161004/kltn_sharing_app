# Address Autocomplete Feature Guide

## Overview
Tính năng autocomplete địa chỉ giúp người dùng nhập địa chỉ dễ dàng hơn và tự động lấy tọa độ (latitude, longitude) từ địa chỉ được chọn.

## Changes Made

### 1. New Widget: `AddressAutocompleteField`
**File:** `lib/presentation/widgets/address_autocomplete_field.dart`

Một widget TextField tái sử dụng với tính năng:
- ✅ Autocomplete suggestions khi nhập
- ✅ Hiển thị gợi ý địa chỉ dưới dạng dropdown
- ✅ Tự động lấy lat/long khi chọn địa chỉ
- ✅ Callback `onAddressSelected(lat, lon, address)`
- ✅ Loading indicator khi đang tìm kiếm
- ✅ Validation support

### 2. New Service: `AddressSuggestionService`
**File:** `lib/data/services/address_suggestion_service.dart`

Singleton service quản lý:
- `getAddressPredictions(query)` - Lấy danh sách gợi ý từ query
- `getLocationFromAddress(address)` - Geocode địa chỉ → lat/long
- `getAddressFromLocation(lat, lon)` - Reverse geocode → địa chỉ
- Model: `LocationPrediction` - Chứa address + lat + lon

### 3. Updated: `StoreInformationScreen`
**File:** `lib/presentation/screens/profile/store_information_screen.dart`

Thay thế `CustomTextField` bằng `AddressAutocompleteField` cho field địa chỉ:
```dart
AddressAutocompleteField(
  controller: _addressController,
  label: 'Địa chỉ',
  onAddressSelected: (latitude, longitude, address) {
    setState(() {
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
    });
  },
)
```

### 4. Updated Dependencies
**File:** `pubspec.yaml`

Thêm `google_places_flutter: ^2.0.8` (sẵn sàng cho tích hợp Google Places API nâng cao)

## How to Use in Your Screens

### Basic Usage
```dart
import 'package:kltn_sharing_app/presentation/widgets/address_autocomplete_field.dart';

// In your build method:
AddressAutocompleteField(
  controller: _addressController,
  label: 'Địa chỉ',
  hintText: 'Nhập địa chỉ của bạn',
  onAddressSelected: (latitude, longitude, address) {
    print('Selected: $address');
    print('Coordinates: $latitude, $longitude');
    
    // Use lat/long for API calls
    _itemApiService.createItem(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  },
)
```

### With Validation
```dart
AddressAutocompleteField(
  controller: _addressController,
  label: 'Địa chỉ',
  onAddressSelected: (latitude, longitude, address) {
    // Handle selection
  },
  // Validation happens in form
)
```

## Using AddressSuggestionService Directly

### Get Address from Coordinates (Reverse Geocoding)
```dart
import 'package:kltn_sharing_app/data/services/address_suggestion_service.dart';

final service = AddressSuggestionService();
final address = await service.getAddressFromLocation(10.7769, 106.7009);
print('Address: $address'); // "123 Đường Nguyễn Huệ, Quận 1, TPHCM"
```

### Get Coordinates from Address (Geocoding)
```dart
final prediction = await service.getLocationFromAddress('Ho Chi Minh City');
if (prediction != null) {
  print('Lat: ${prediction.latitude}');
  print('Lon: ${prediction.longitude}');
}
```

## Integration with API Services

### Pass Location to Item API
```dart
class ItemApiService extends BaseApiService {
  Future<void> createItem({
    required String name,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await dio.post(
      '/api/v2/items',
      data: {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      },
    );
  }
}
```

### Pass Location from Widget
```dart
// In create_product_modal.dart or similar
final addressService = AddressSuggestionService();

// When user selects address via autocomplete:
final prediction = await addressService.getLocationFromAddress(address);
if (prediction != null) {
  await _itemApiService.createItem(
    name: _nameController.text,
    latitude: prediction.latitude,
    longitude: prediction.longitude,
    address: prediction.address,
  );
}
```

## Flow Diagram

```
User Types Address
        ↓
AddressAutocompleteField
        ↓
onChanged Event
        ↓
AddressSuggestionService.getAddressPredictions()
        ↓
Geocoding → LocationPrediction (lat, lon)
        ↓
Display Dropdown Suggestions
        ↓
User Selects Address
        ↓
onAddressSelected Callback
        ↓
Get (lat, lon) → Use in API
```

## Screen Supports Autocomplete

✅ **StoreInformationScreen** - Địa chỉ cửa hàng
⏳ **CreateProductModal** - Có thể thêm cho sản phẩm
⏳ **Other Address Fields** - Có thể áp dụng cho bất kỳ field nào

## Future Enhancements

1. **Google Places API Integration**
   - Thay thế Geocoding bằng Google Places API
   - Chi phí: ~$0.015 per request
   - Tính năng tốt hơn, gợi ý chính xác hơn

2. **Caching**
   - Cache gợi ý để tránh lặp lại request
   - Sử dụng SharedPreferences

3. **Recent Addresses**
   - Lưu danh sách địa chỉ gần đây
   - Hiển thị nhanh khi người dùng focus

## Testing

### Test Flow
1. Go to **Store Information Screen**
2. Tap on **Địa chỉ** field
3. Type "Ho Chi Minh" or "Hanoi"
4. See autocomplete suggestions
5. Select one address
6. Verify: address appears in TextField + lat/lon captured

### Expected Results
```
Input: "Ho Chi Minh"
↓
Suggestion: "Ho Chi Minh City, Vietnam"
Lat: 10.7769
Lon: 106.7009
```

## Notes

- Geocoding hiện sử dụng offline database → tốc độ nhanh
- Cần internet connection để geocode
- Nếu không tìm thấy → sử dụng default coordinates
- Có thể thêm Google Places API key sau để tính năng tốt hơn
