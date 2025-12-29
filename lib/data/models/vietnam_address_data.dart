import 'address_model.dart';

class VietnamAddressData {
  static final List<Province> provinces = [
    Province(
      id: '01',
      name: 'Hà Nội',
      districts: [
        District(
          id: '01_01',
          name: 'Hoàn Kiếm',
          provinceId: '01',
          wards: [
            Ward(id: '01_01_01', name: 'Hàng Đào', districtId: '01_01'),
            Ward(id: '01_01_02', name: 'Tràng Tiền', districtId: '01_01'),
            Ward(id: '01_01_03', name: 'Cửa Đông', districtId: '01_01'),
          ],
        ),
        District(
          id: '01_02',
          name: 'Ba Đình',
          provinceId: '01',
          wards: [
            Ward(id: '01_02_01', name: 'Phúc Xá', districtId: '01_02'),
            Ward(id: '01_02_02', name: 'Điện Biên', districtId: '01_02'),
            Ward(id: '01_02_03', name: 'Liễu Giai', districtId: '01_02'),
          ],
        ),
        District(
          id: '01_03',
          name: 'Cầu Giấy',
          provinceId: '01',
          wards: [
            Ward(id: '01_03_01', name: 'Dịch Vọng', districtId: '01_03'),
            Ward(id: '01_03_02', name: 'Yên Hòa', districtId: '01_03'),
            Ward(id: '01_03_03', name: 'Quan Hoa', districtId: '01_03'),
          ],
        ),
      ],
    ),
    Province(
      id: '02',
      name: 'TP Hồ Chí Minh',
      districts: [
        District(
          id: '02_01',
          name: 'Quận 1',
          provinceId: '02',
          wards: [
            Ward(id: '02_01_01', name: 'Bến Nghé', districtId: '02_01'),
            Ward(id: '02_01_02', name: 'Bến Thành', districtId: '02_01'),
            Ward(id: '02_01_03', name: 'Cầu Ông Lãnh', districtId: '02_01'),
          ],
        ),
        District(
          id: '02_02',
          name: 'Quận 2',
          provinceId: '02',
          wards: [
            Ward(id: '02_02_01', name: 'An Phú', districtId: '02_02'),
            Ward(id: '02_02_02', name: 'Bình Trưng Đông', districtId: '02_02'),
            Ward(id: '02_02_03', name: 'Bình Trưng Tây', districtId: '02_02'),
          ],
        ),
        District(
          id: '02_03',
          name: 'Quận 3',
          provinceId: '02',
          wards: [
            Ward(id: '02_03_01', name: 'Võ Thị Sáu', districtId: '02_03'),
            Ward(id: '02_03_02', name: 'Nguyễn Hữu Cảnh', districtId: '02_03'),
            Ward(id: '02_03_03', name: 'Phường 9', districtId: '02_03'),
          ],
        ),
      ],
    ),
    Province(
      id: '03',
      name: 'Đà Nẵng',
      districts: [
        District(
          id: '03_01',
          name: 'Hải Châu',
          provinceId: '03',
          wards: [
            Ward(id: '03_01_01', name: 'Phước Ninh', districtId: '03_01'),
            Ward(id: '03_01_02', name: 'Thạch Thang', districtId: '03_01'),
            Ward(id: '03_01_03', name: 'Bình Hiên', districtId: '03_01'),
          ],
        ),
        District(
          id: '03_02',
          name: 'Cẩm Lệ',
          provinceId: '03',
          wards: [
            Ward(id: '03_02_01', name: 'Khuê Trung', districtId: '03_02'),
            Ward(id: '03_02_02', name: 'Thọ Quang', districtId: '03_02'),
            Ward(id: '03_02_03', name: 'Hòa Xuân', districtId: '03_02'),
          ],
        ),
      ],
    ),
    Province(
      id: '04',
      name: 'Hải Phòng',
      districts: [
        District(
          id: '04_01',
          name: 'Hồng Bàng',
          provinceId: '04',
          wards: [
            Ward(id: '04_01_01', name: 'Minh Khai', districtId: '04_01'),
            Ward(id: '04_01_02', name: 'Hải Tân', districtId: '04_01'),
            Ward(id: '04_01_03', name: 'Phạm Hùng', districtId: '04_01'),
          ],
        ),
        District(
          id: '04_02',
          name: 'Ngô Quyền',
          provinceId: '04',
          wards: [
            Ward(id: '04_02_01', name: 'Máy Tơ', districtId: '04_02'),
            Ward(id: '04_02_02', name: 'Lạch Tray', districtId: '04_02'),
            Ward(id: '04_02_03', name: 'Vạn Hương', districtId: '04_02'),
          ],
        ),
      ],
    ),
  ];

  /// Get all provinces
  static List<Province> getProvinces() => provinces;

  /// Get districts by province ID
  static List<District> getDistrictsByProvinceId(String provinceId) {
    final province = provinces.firstWhere(
      (p) => p.id == provinceId,
      orElse: () => provinces[0],
    );
    return province.districts;
  }

  /// Get wards by district ID
  static List<Ward> getWardsByDistrictId(String districtId) {
    for (final province in provinces) {
      try {
        final district =
            province.districts.firstWhere((d) => d.id == districtId);
        return district.wards;
      } catch (e) {
        continue;
      }
    }
    return [];
  }

  /// Get province by ID
  static Province? getProvinceById(String id) {
    try {
      return provinces.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get district by ID
  static District? getDistrictById(String id) {
    for (final province in provinces) {
      try {
        return province.districts.firstWhere((d) => d.id == id);
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Get ward by ID
  static Ward? getWardById(String id) {
    for (final province in provinces) {
      for (final district in province.districts) {
        try {
          return district.wards.firstWhere((w) => w.id == id);
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
}
