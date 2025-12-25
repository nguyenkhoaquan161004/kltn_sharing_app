import 'models/admin_model.dart';
import 'models/user_model.dart';
import 'models/item_model.dart';
import 'models/message_model.dart';
import 'models/gamification_model.dart';
import 'models/transaction_model.dart';
import 'models/location_model.dart';
import 'models/category_model.dart';
import 'models/item_interest_model.dart';
import 'models/notification_model.dart';
import 'models/user_badge_model.dart';
import 'models/badge_model.dart';

/// Mock data class chứa tất cả dữ liệu ảo cho phát triển
class MockData {
  // ==================== LOCATIONS ====================
  static final List<LocationModel> locations = [
    LocationModel(
      locationId: 1,
      name: 'TP.HCM - Quận 1',
      latitude: 10.7769,
      longitude: 106.7009,
    ),
    LocationModel(
      locationId: 2,
      name: 'TP.HCM - Quận 3',
      latitude: 10.7873,
      longitude: 106.6804,
    ),
    LocationModel(
      locationId: 3,
      name: 'TP.HCM - Quận 5',
      latitude: 10.7626,
      longitude: 106.6549,
    ),
    LocationModel(
      locationId: 4,
      name: 'TP.HCM - Quận 7',
      latitude: 10.7343,
      longitude: 106.7247,
    ),
    LocationModel(
      locationId: 5,
      name: 'Hà Nội - Hoàn Kiếm',
      latitude: 21.0285,
      longitude: 105.8542,
    ),
    LocationModel(
      locationId: 6,
      name: 'Hà Nội - Cầu Giấy',
      latitude: 21.0452,
      longitude: 105.7857,
    ),
  ];

  // ==================== CATEGORIES ====================
  static final List<CategoryModel> categories = [
    CategoryModel(categoryId: 1, name: 'Quần áo'),
    CategoryModel(categoryId: 2, name: 'Giày dép'),
    CategoryModel(categoryId: 3, name: 'Điện tử'),
    CategoryModel(categoryId: 4, name: 'Sách'),
    CategoryModel(categoryId: 5, name: 'Đồ chơi'),
    CategoryModel(categoryId: 6, name: 'Nội thất'),
    CategoryModel(categoryId: 7, name: 'Thể thao'),
    CategoryModel(categoryId: 8, name: 'Khác'),
  ];

  // ==================== BADGES ====================
  static final List<BadgeModel> badges = [
    BadgeModel(
      badgeId: 1,
      name: 'Người chia sẻ mới',
      description: 'Chia sẻ sản phẩm đầu tiên của bạn',
      icon: '🌟',
    ),
    BadgeModel(
      badgeId: 2,
      name: 'Nhà chia sẻ lạc quan',
      description: 'Nhận được 5 lần đánh giá tích cực liên tiếp',
      icon: '⭐',
    ),
    BadgeModel(
      badgeId: 3,
      name: 'Nhân từ',
      description: 'Chia sẻ tổng cộng 100 sản phẩm',
      icon: '❤️',
    ),
    BadgeModel(
      badgeId: 4,
      name: 'Người nhận hào phóng',
      description: 'Nhận được 50 sản phẩm',
      icon: '🎁',
    ),
    BadgeModel(
      badgeId: 5,
      name: 'Kỵ sĩ mạo hiểm',
      description: 'Hoàn thành 10 giao dịch',
      icon: '⚔️',
    ),
  ];

  // ==================== ADMINS ====================
  static final List<AdminModel> admins = [
    AdminModel(
      adminId: 1,
      name: 'Admin Chính',
      email: 'admin@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'super_admin',
      createdAt: DateTime(2024, 1, 15),
    ),
    AdminModel(
      adminId: 2,
      name: 'Quản lý Nội dung',
      email: 'content@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'admin',
      createdAt: DateTime(2024, 2, 1),
    ),
    AdminModel(
      adminId: 3,
      name: 'Người kiểm duyệt',
      email: 'moderator@kltn.com',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      permissionLevel: 'moderator',
      createdAt: DateTime(2024, 3, 10),
    ),
  ];

  // ==================== USERS ====================
  static final List<UserModel> users = [
    UserModel(
      userId: 1,
      name: 'Nguyễn Khoa Quân',
      email: 'quan@example.com',
      phone: '0912345678',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'premium',
      trustScore: 95,
      createdAt: DateTime(2023, 6, 15),
      avatar: 'https://i.pravatar.cc/150?img=1',
      address: '8A/12A Thái Văn Lung, Q.1, TP.HCM',
    ),
    UserModel(
      userId: 2,
      name: 'Trần Minh Anh',
      email: 'minh.anh@example.com',
      phone: '0987654321',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 88,
      createdAt: DateTime(2023, 7, 20),
      avatar: 'https://i.pravatar.cc/150?img=2',
      address: 'Quận 3, TP.HCM',
    ),
    UserModel(
      userId: 3,
      name: 'Phạm Thị Bích',
      email: 'bich@example.com',
      phone: '0901112233',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'user',
      trustScore: 72,
      createdAt: DateTime(2023, 8, 10),
      avatar: 'https://i.pravatar.cc/150?img=3',
      address: 'Quận 5, TP.HCM',
    ),
    UserModel(
      userId: 4,
      name: 'Đinh Văn Cường',
      email: 'cuong@example.com',
      phone: '0944556677',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 85,
      createdAt: DateTime(2023, 9, 5),
      avatar: 'https://i.pravatar.cc/150?img=4',
      address: 'Quận 7, TP.HCM',
    ),
    UserModel(
      userId: 5,
      name: 'Lý Thanh Tú',
      email: 'thanh.tu@example.com',
      phone: '0967788990',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'user',
      trustScore: 68,
      createdAt: DateTime(2023, 10, 12),
      avatar: 'https://i.pravatar.cc/150?img=5',
      address: 'Hà Nội',
    ),
    UserModel(
      userId: 6,
      name: 'Võ Hoàng Huy',
      email: 'hoang.huy@example.com',
      phone: '0988990011',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'premium',
      trustScore: 92,
      createdAt: DateTime(2023, 11, 8),
      avatar: 'https://i.pravatar.cc/150?img=6',
      address: 'Quận 1, TP.HCM',
    ),
    UserModel(
      userId: 7,
      name: 'Ngô Thị Thu Hà',
      email: 'thu.ha@example.com',
      phone: '0901234567',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 81,
      createdAt: DateTime(2023, 12, 3),
      avatar: 'https://i.pravatar.cc/150?img=7',
      address: 'Quận 2, TP.HCM',
    ),
    UserModel(
      userId: 8,
      name: 'Hoàng Minh Hải',
      email: 'minh.hai@example.com',
      phone: '0912567890',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'user',
      trustScore: 76,
      createdAt: DateTime(2024, 1, 10),
      avatar: 'https://i.pravatar.cc/150?img=8',
      address: 'Quận 11, TP.HCM',
    ),
    UserModel(
      userId: 9,
      name: 'Phan Quốc Anh',
      email: 'quoc.anh@example.com',
      phone: '0923456789',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'premium',
      trustScore: 89,
      createdAt: DateTime(2024, 1, 15),
      avatar: 'https://i.pravatar.cc/150?img=9',
      address: 'Quận 4, TP.HCM',
    ),
    UserModel(
      userId: 10,
      name: 'Tạ Minh Tuấn',
      email: 'minh.tuan@example.com',
      phone: '0934567890',
      passwordHash: '\$2b\$12\$K1.hQ5b7Zs8G9X4Q2K1Z0eVqQ2K1Z0e',
      role: 'seller',
      trustScore: 79,
      createdAt: DateTime(2024, 2, 1),
      avatar: 'https://i.pravatar.cc/150?img=10',
      address: 'Quận 9, TP.HCM',
    ),
  ];

  // ==================== ITEMS ====================
  static final List<ItemModel> items = [
    ItemModel(
      itemId: 1,
      userId: 1,
      name: 'Giày Nike Air Max mới',
      description:
          '''Giày Nike Air Max 90 chính hãng 100%, tình trạng như mới, mới mua được 3 tháng, chỉ mang 2 lần trong nhà. Chất liệu cao cấp, đế bền, thoáng khí tốt. Phù hợp cho những ai yêu thích thể thao hoặc đi casual hàng ngày.

Thông tin chi tiết:
• Hãng: Nike chính hãng
• Model: Air Max 90
• Kích cỡ: 42 (Size US 8.5)
• Màu sắc: Trắng xám
• Tình trạng: Như mới
• Lần mang: 2 lần
• Đế: Bền chắc, không trầy xước
• Chất liệu: Canvas + Leather, thoáng khí
• Đi kèm: Hộp nguyên bản, túi bụi, giấy tờ đầy đủ

Sản phẩm rất bền, phù hợp cho những ai yêu thích style sneaker. Mình không còn nhu cầu sử dụng nên chia sẻ để bạn khác có cơ hội sử dụng. Bạn nào quan tâm có thể liên hệ để xem thực tế hoặc chat hỏi thêm thông tin. Mình ở quận 1, có thể gặp trực tiếp hoặc giao hàng gần đây.''',
      quantity: 1,
      status: 'available',
      categoryId: 2,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 30)),
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      price: 0,
    ),
    ItemModel(
      itemId: 2,
      userId: 2,
      name: 'Áo thun cotton',
      description:
          '''Áo thun cotton chất lượng cao, 100% cotton tự nhiên, màu đen, size M, mất size nhưng rất đẹp. Mua ở shop lên tới 300k, giờ muốn chia sẻ để bạn khác có cơ hội dùng.

Chi tiết sản phẩm:
• Chất liệu: 100% Cotton organic
• Màu: Đen sâu
• Size: M (phù hợp cho người cao từ 1m55-1m70)
• Tình trạng: 95% - Như mới, chỉ mang 1 lần
• Đặc tính: Thoáng mát, mềm mại, thấm mồ hôi tốt
• Phù hợp: Mặc thường ngày, thể thao, ngủ

Áo không bị xù, không bị xấy, không bị phai màu. Giặt đúng cách sẽ bền lâu. Nếu quan tâm hãy liên hệ ngay.''',
      quantity: 3,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 45)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 50000,
    ),
    ItemModel(
      itemId: 3,
      userId: 3,
      name: 'Sách "Cách dạy con thông minh"',
      description:
          '''Sách hay về giáo dục trẻ em, tình trạng tốt, có chữ ký tác giả ghi tặng. Cuốn sách này được các chuyên gia đánh giá cao về kỹ năng dạy dỗ trẻ em hiệu quả.

Thông tin chi tiết:
• Tác giả: Nguyễn Văn Dũng
• Năm xuất bản: 2022
• Số trang: 350 trang
• Kích thước: A5
• Tình trạng: Rất tốt
• Đặc biệt: Có chữ ký tác giả ghi tặng

Nội dung sách bao gồm:
- Những bí quyết dạy con thông minh
- Phương pháp giáo dục hiện đại
- Cách xử lý hành vi trẻ em
- Phát triển kỹ năng cho trẻ

Sách không bị dơ, không bị nát góc, trang sạch. Nếu bạn quan tâm đến giáo dục trẻ em, đây là cuốn sách không nên bỏ qua.''',
      quantity: 2,
      status: 'available',
      categoryId: 4,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      price: 0,
    ),
    ItemModel(
      itemId: 4,
      userId: 4,
      name: 'Ghế gỗ ăn cơm',
      description:
          '''Ghế gỗ ăn cơm, bộ 4 cái, màu nâu sâu, hơi cũ nhưng còn chắc chỉ, tất cả 4 cái đều nguyên vẹn. Phù hợp cho gia đình hoặc nhà hàng nhỏ.

Thông tin chi tiết:
• Số lượng: 4 ghế
• Chất liệu: Gỗ tự nhiên
• Màu: Nâu sâu
• Kích thước: 40cm x 45cm (cao)
• Tình trạng: Còn bền, hơi cũ nhưng vẫn sử dụng tốt
• Đặc tính: Chắc chỉ, không cưa cứng

Tất cả các ghế đều còn 4 chân chắc chắn, không bị xiêu. Mặt ghế không bị bỏng hay trầy xước lớn. Ghế có thể sử dụng ngay mà không cần sửa chữa.

Lý do chia sẻ: Gia đình mình mua bộ bàn ghế mới nên không còn cần dùng bộ này nữa.''',
      quantity: 4,
      status: 'available',
      categoryId: 6,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      price: 500000,
    ),
    ItemModel(
      itemId: 5,
      userId: 5,
      name: 'Laptop Asus cũ',
      description:
          'Laptop Asus VivoBook 15, Intel i5, RAM 8GB, SSD 512GB, pin còn tốt',
      quantity: 1,
      status: 'pending',
      categoryId: 3,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 20)),
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      price: 0,
    ),
    ItemModel(
      itemId: 6,
      userId: 1,
      name: 'Bộ vợt cầu lông',
      description: 'Bộ vợt cầu lông cao cấp, 2 cái, có túi xách, ít dùng',
      quantity: 2,
      status: 'available',
      categoryId: 7,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 75)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 200000,
    ),
    ItemModel(
      itemId: 7,
      userId: 2,
      name: 'Quần jeans nam',
      description:
          'Quần jeans nam hiệu Levi\'s, size 32, màu xanh, tình trạng mới',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 55)),
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      price: 0,
    ),
    ItemModel(
      itemId: 8,
      userId: 6,
      name: 'Đồ chơi Lego',
      description:
          'Bộ Lego City, hơn 500 mảnh, hộp nguyên bản, từ 5 tuổi trở lên',
      quantity: 1,
      status: 'available',
      categoryId: 5,
      locationId: 6,
      expiryDate: DateTime.now().add(Duration(days: 100)),
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      price: 150000,
    ),
    ItemModel(
      itemId: 9,
      userId: 7,
      name: 'Túi xách nữ da thật',
      description: 'Túi xách nữ da thật Italy, màu đen, tình trạng như mới',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 50)),
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      price: 0,
    ),
    ItemModel(
      itemId: 10,
      userId: 8,
      name: 'Xe đạp Touring',
      description:
          'Xe đạp Touring chuyên dụng, 21 tốc độ, khung nhôm, bao chất',
      quantity: 1,
      status: 'available',
      categoryId: 7,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 80)),
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      price: 0,
    ),
    ItemModel(
      itemId: 11,
      userId: 9,
      name: 'Camera DSLR Canon',
      description:
          'Camera Canon EOS 700D, tặng kèm 2 ống kính, máy quay video rất tốt',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 120)),
      createdAt: DateTime.now().subtract(Duration(days: 11)),
      price: 300000,
    ),
    ItemModel(
      itemId: 12,
      userId: 10,
      name: 'Giường tầng gỗ',
      description: 'Giường tầng gỗ công nghiệp, 2 chiều ngủ, có tủ, bao chắc',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      price: 0,
    ),
    ItemModel(
      itemId: 13,
      userId: 1,
      name: 'Tai nghe Sony WH-1000XM4',
      description: 'Tai nghe chống ồn cao cấp, pin 30h, âm thanh cực tốt',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 0,
    ),
    ItemModel(
      itemId: 14,
      userId: 4,
      name: 'Bộ bàn ghế sofa',
      description: 'Bộ sofa phòng khách 3 chỗ + 2 ghế đơn, da bò tây',
      quantity: 1,
      status: 'pending',
      categoryId: 6,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 110)),
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      price: 400000,
    ),
    ItemModel(
      itemId: 15,
      userId: 3,
      name: 'Sách tiếng Anh chuyên ngành',
      description:
          'Bộ 5 quyển sách tiếng Anh, kỹ thuật phần mềm, xuất bản từ 2022',
      quantity: 5,
      status: 'available',
      categoryId: 4,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 70)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 0,
    ),
    ItemModel(
      itemId: 16,
      userId: 1,
      name: 'Laptop Dell XPS 15',
      description:
          'Laptop Dell XPS 15 inch, Intel i7, RAM 16GB, SSD 512GB, RTX 3050, pin 8h, bảo hành đến tháng 6/2025. Máy rất bền và mạnh, phù hợp cho lập trình và đồ họa.',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      price: 800000,
    ),
    ItemModel(
      itemId: 17,
      userId: 1,
      name: 'Giá sách gỗ 5 tầng',
      description:
          'Giá sách gỗ công nghiệp 5 tầng, kích thước 180x80cm, chắc chắn, có thể đặt ở phòng ngủ hoặc phòng khách. Không lỗi, chỉ cần di chuyển.',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      price: 0,
    ),
    ItemModel(
      itemId: 18,
      userId: 1,
      name: 'Đèn bàn LED thông minh',
      description:
          'Đèn bàn LED thông minh có điều chỉnh nhiệt độ màu và độ sáng, tiết kiệm điện, không phát sinh nhiệt, phù hợp cho học tập và làm việc.',
      quantity: 2,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 45)),
      createdAt: DateTime.now().subtract(Duration(days: 18)),
      price: 150000,
    ),
    ItemModel(
      itemId: 19,
      userId: 1,
      name: 'Bộ bàn ghế học tập trẻ em',
      description:
          'Bộ bàn ghế học tập cho trẻ em, có thể điều chỉnh chiều cao, ghế thoải mái, thiết kế an toàn. Màu xanh, tình trạng 98%.',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 30)),
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      price: 0,
    ),
    ItemModel(
      itemId: 20,
      userId: 1,
      name: 'Bộ quốc tế tờ rơi',
      description:
          'Bộ quốc tế tờ rơi tiếng Anh và Pháp, có giá trị tham khảo cao, tình trạng như mới, có túi đựng, có bản đồ chi tiết.',
      quantity: 1,
      status: 'available',
      categoryId: 4,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 120)),
      createdAt: DateTime.now().subtract(Duration(days: 35)),
      price: 0,
    ),
    ItemModel(
      itemId: 21,
      userId: 1,
      name: 'Dây cáp sạc nhanh Type-C',
      description:
          'Bộ 3 dây sạc nhanh Type-C, dài 2m, hỗ trợ sạc nhanh 65W, tương thích với mọi điện thoại và laptop Type-C, bền bỉ, chứng chỉ an toàn.',
      quantity: 3,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 40)),
      price: 0,
    ),
    ItemModel(
      itemId: 22,
      userId: 2,
      name: 'Áo khoác nam',
      description:
          'Áo khoác nam chế độ, chất liệu vải dù, size M, màu xanh navy, chống nước, tình trạng như mới',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 45)),
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      price: 0,
    ),
    ItemModel(
      itemId: 23,
      userId: 3,
      name: 'Giày sneaker Adidas',
      description:
          'Giày sneaker Adidas Ultraboost, size 42, màu trắng đen, tình trạng 90%',
      quantity: 1,
      status: 'available',
      categoryId: 2,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      price: 250000,
    ),
    ItemModel(
      itemId: 24,
      userId: 4,
      name: 'Bàn gỗ màu trắng',
      description:
          'Bàn gỗ công nghiệp màu trắng, kích thước 120x60cm, chắc chắn, phù hợp làm bàn học hoặc bàn làm việc',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 75)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 300000,
    ),
    ItemModel(
      itemId: 25,
      userId: 5,
      name: 'Sách lập trình Python',
      description:
          'Sách lập trình Python, tác giả Guido Van Rossum, 500+ trang, tình trạng mới 98%',
      quantity: 1,
      status: 'available',
      categoryId: 4,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 0,
    ),
    ItemModel(
      itemId: 26,
      userId: 1,
      name: 'Điện thoại iPhone 12',
      description:
          'iPhone 12 màu đen, bộ nhớ 128GB, pin đủ, chỉ có 1 vết nhỏ trên mặt sau, hoạt động 100%',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      price: 500000,
    ),
    ItemModel(
      itemId: 27,
      userId: 6,
      name: 'Ghế xoay văn phòng',
      description:
          'Ghế xoay văn phòng, đệm mỏng, tay để, có bánh xe, màu đen, tình trạng tốt',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 50)),
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      price: 150000,
    ),
    ItemModel(
      itemId: 28,
      userId: 2,
      name: 'Quần short nữ',
      description:
          'Quần short nữ cotton, size S, màu trắng, ôm nhẹ, thoáng mát, perfect cho mùa hè',
      quantity: 2,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 40)),
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      price: 0,
    ),
    ItemModel(
      itemId: 29,
      userId: 7,
      name: 'Dép sandal nam',
      description:
          'Dép sandal nam chất liệu da, size 42, màu nâu, êm chân, bền chắc',
      quantity: 1,
      status: 'available',
      categoryId: 2,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 55)),
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      price: 100000,
    ),
    ItemModel(
      itemId: 30,
      userId: 8,
      name: 'Tủ lạnh mini',
      description:
          'Tủ lạnh mini 50L, điều chỉnh nhiệt độ, tiêu thụ điện thấp, phù hợp cho phòng trọ',
      quantity: 1,
      status: 'pending',
      categoryId: 3,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 100)),
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      price: 400000,
    ),
    ItemModel(
      itemId: 31,
      userId: 9,
      name: 'Đồ chơi robot',
      description:
          'Robot điều khiển từ xa, pin 2h, tính năng lập trình cơ bản, phù hợp từ 8 tuổi',
      quantity: 1,
      status: 'available',
      categoryId: 5,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 80)),
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      price: 200000,
    ),
    ItemModel(
      itemId: 32,
      userId: 10,
      name: 'Máy tập thể dục',
      description:
          'Máy tập gym mini, 6 chế độ, chân có cao su chống trượt, phù hợp cho gia đình',
      quantity: 1,
      status: 'available',
      categoryId: 7,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 120)),
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      price: 350000,
    ),
    ItemModel(
      itemId: 33,
      userId: 1,
      name: 'Bộ cốc sứ 6 chiếc',
      description:
          'Bộ 6 cốc sứ trắng, dung tích 350ml mỗi cốc, chất lượng cao, không độc hại',
      quantity: 1,
      status: 'available',
      categoryId: 6,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 70)),
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      price: 0,
    ),
    ItemModel(
      itemId: 34,
      userId: 3,
      name: 'Giáo trình tiếng Trung',
      description:
          'Giáo trình tiếng Trung HSK 4, 300 trang, kèm CD, tình trạng 95%',
      quantity: 1,
      status: 'available',
      categoryId: 4,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 85)),
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      price: 0,
    ),
    ItemModel(
      itemId: 35,
      userId: 4,
      name: 'Nước hoa nam',
      description:
          'Nước hoa nam hiệu Dior, 100ml, mùi fresh, chỉ dùng 3 lần, còn như mới',
      quantity: 1,
      status: 'available',
      categoryId: 8,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 200)),
      createdAt: DateTime.now().subtract(Duration(days: 11)),
      price: 0,
    ),
    ItemModel(
      itemId: 36,
      userId: 5,
      name: 'Kiếng mát nam nữ',
      description:
          'Kính mát UV 400, chống lóa, phù hợp nam nữ, tình trạng mới 98%',
      quantity: 2,
      status: 'available',
      categoryId: 8,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 150)),
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      price: 50000,
    ),
    ItemModel(
      itemId: 37,
      userId: 6,
      name: 'Chuột không dây Logitech',
      description:
          'Chuột không dây Logitech, pin AA, độ nhạy 1000DPI, màu xám, hoạt động tốt',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 60)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 80000,
    ),
    ItemModel(
      itemId: 38,
      userId: 7,
      name: 'Bàn phím cơ RGB',
      description:
          'Bàn phím cơ RGB, 104 phím, switch mechanical, đèn nền 7 màu',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 14)),
      price: 300000,
    ),
    ItemModel(
      itemId: 39,
      userId: 8,
      name: 'Chăn lông cừu',
      description:
          'Chăn lông cừu kích thước 200x150cm, màu kem, ấm áp, dễ vệ sinh',
      quantity: 2,
      status: 'available',
      categoryId: 6,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 120)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 0,
    ),
    ItemModel(
      itemId: 40,
      userId: 9,
      name: 'Gối công thái học',
      description:
          'Gối công thái học cao su non, giúp giảm đau cổ, tình trạng mới',
      quantity: 3,
      status: 'available',
      categoryId: 6,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 80)),
      createdAt: DateTime.now().subtract(Duration(days: 6)),
      price: 120000,
    ),
    ItemModel(
      itemId: 41,
      userId: 10,
      name: 'Dầu gội đầu',
      description:
          'Dầu gội đầu thiên nhiên 500ml, không silicone, cho tóc dầu, hàng mới',
      quantity: 4,
      status: 'available',
      categoryId: 8,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 200)),
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      price: 0,
    ),
    ItemModel(
      itemId: 42,
      userId: 1,
      name: 'Áo tanktop nam',
      description:
          'Áo tanktop nam thun cotton, size L, màu xám, phù hợp tập gym',
      quantity: 3,
      status: 'available',
      categoryId: 1,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 35)),
      createdAt: DateTime.now().subtract(Duration(days: 1)),
      price: 0,
    ),
    ItemModel(
      itemId: 43,
      userId: 2,
      name: 'Mũ lưỡi trai',
      description:
          'Mũ lưỡi trai thể thao, chất liệu cotton, màu đen, chống nắng tốt',
      quantity: 5,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 4)),
      price: 50000,
    ),
    ItemModel(
      itemId: 44,
      userId: 3,
      name: 'Đôi tất thể thao',
      description:
          'Đôi tất thể thao, tập hợp 10 đôi, chất cotton, hỗ trợ cổ chân',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 120)),
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      price: 0,
    ),
    ItemModel(
      itemId: 45,
      userId: 4,
      name: 'Giầy tập gym',
      description: 'Giầy tập gym, đế bọt, hỗ trợ cổ chân, màu xám, size 41',
      quantity: 1,
      status: 'available',
      categoryId: 2,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 70)),
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      price: 150000,
    ),
    ItemModel(
      itemId: 46,
      userId: 5,
      name: 'Quần yoga nữ',
      description:
          'Quần yoga nữ cao cấp, size M, màu tím, co giãn tốt, thoáng mát',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 50)),
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      price: 0,
    ),
    ItemModel(
      itemId: 47,
      userId: 6,
      name: 'Thảm yoga 5mm',
      description:
          'Thảm yoga 5mm, kích thước 173x61cm, chất liệu TPE, chống trượt',
      quantity: 2,
      status: 'available',
      categoryId: 7,
      locationId: 1,
      expiryDate: DateTime.now().add(Duration(days: 100)),
      createdAt: DateTime.now().subtract(Duration(days: 9)),
      price: 180000,
    ),
    ItemModel(
      itemId: 48,
      userId: 7,
      name: 'Túi xách công sở',
      description:
          'Túi xách công sở da PU, màu đen, kích thước lớn, ngăn nhiều, chất lượng tốt',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 2,
      expiryDate: DateTime.now().add(Duration(days: 80)),
      createdAt: DateTime.now().subtract(Duration(days: 12)),
      price: 200000,
    ),
    ItemModel(
      itemId: 49,
      userId: 8,
      name: 'Ví da nam',
      description:
          'Ví da nam chính hãng, da bò đỏ, giấu RFID, tình trạng như mới',
      quantity: 1,
      status: 'available',
      categoryId: 1,
      locationId: 3,
      expiryDate: DateTime.now().add(Duration(days: 150)),
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      price: 0,
    ),
    ItemModel(
      itemId: 50,
      userId: 9,
      name: 'Dây đeo điện thoại',
      description:
          'Dây đeo điện thoại cotton, có móc kim loại, phù hợp cho mọi điện thoại',
      quantity: 5,
      status: 'available',
      categoryId: 3,
      locationId: 4,
      expiryDate: DateTime.now().add(Duration(days: 90)),
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      price: 0,
    ),
    ItemModel(
      itemId: 51,
      userId: 10,
      name: 'Bộ tai nghe Bluetooth',
      description: 'Tai nghe Bluetooth TWS, pin 6h, chống nước IPX5, bass sâu',
      quantity: 1,
      status: 'available',
      categoryId: 3,
      locationId: 5,
      expiryDate: DateTime.now().add(Duration(days: 75)),
      createdAt: DateTime.now().subtract(Duration(days: 8)),
      price: 250000,
    ),
  ];

  // ==================== MESSAGES ====================
  static final List<MessageModel> messages = [
    MessageModel(
      messageId: 1,
      senderId: 1,
      receiverId: 2,
      itemId: 1,
      content: 'Bạn còn giày này không? Tôi rất quan tâm.',
      createdAt: DateTime.now().subtract(Duration(hours: 24)),
    ),
    MessageModel(
      messageId: 2,
      senderId: 2,
      receiverId: 1,
      itemId: 1,
      content: 'Còn chứ! Bạn muốn xem trực tiếp không?',
      createdAt: DateTime.now().subtract(Duration(hours: 23)),
    ),
    MessageModel(
      messageId: 3,
      senderId: 3,
      receiverId: 4,
      itemId: 4,
      content: 'Ghế có thể giao ở quận 1 được không?',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    MessageModel(
      messageId: 4,
      senderId: 4,
      receiverId: 3,
      itemId: 4,
      content: 'Được thôi, mình có thể giao miễn phí.',
      createdAt: DateTime.now().subtract(Duration(hours: 11)),
    ),
    MessageModel(
      messageId: 5,
      senderId: 5,
      receiverId: 1,
      itemId: null,
      content: 'Xin chào, bạn có quen mình ở trường không?',
      createdAt: DateTime.now().subtract(Duration(hours: 6)),
    ),
    MessageModel(
      messageId: 6,
      senderId: 1,
      receiverId: 5,
      itemId: null,
      content: 'Ừ, cái gì tôi giúp bạn được không?',
      createdAt: DateTime.now().subtract(Duration(hours: 5)),
    ),
    MessageModel(
      messageId: 7,
      senderId: 7,
      receiverId: 6,
      itemId: 8,
      content: 'Bộ Lego này còn không ạ? Giá bao nhiêu?',
      createdAt: DateTime.now().subtract(Duration(hours: 18)),
    ),
    MessageModel(
      messageId: 8,
      senderId: 6,
      receiverId: 7,
      itemId: 8,
      content: 'Còn chứ! Giá mình tính 150k, chất lượng tốt lắm.',
      createdAt: DateTime.now().subtract(Duration(hours: 17)),
    ),
    MessageModel(
      messageId: 9,
      senderId: 8,
      receiverId: 9,
      itemId: 11,
      content: 'Camera này giá bao nhiêu? Có demo không?',
      createdAt: DateTime.now().subtract(Duration(hours: 10)),
    ),
    MessageModel(
      messageId: 10,
      senderId: 9,
      receiverId: 8,
      itemId: 11,
      content: 'Giá 300k, mình có thể cho bạn xem và test trước.',
      createdAt: DateTime.now().subtract(Duration(hours: 9)),
    ),
  ];

  // ==================== GAMIFICATION ====================
  static final List<GamificationModel> gamifications = [
    GamificationModel(
      gamificationId: 1,
      userId: 1,
      points: 3520,
      level: 15,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 2,
      userId: 2,
      points: 2890,
      level: 12,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 3,
      userId: 3,
      points: 1450,
      level: 8,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 4,
      userId: 4,
      points: 2750,
      level: 11,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 5,
      userId: 5,
      points: 1280,
      level: 7,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 6,
      userId: 6,
      points: 3150,
      level: 14,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 7,
      userId: 7,
      points: 2340,
      level: 10,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 8,
      userId: 8,
      points: 1890,
      level: 9,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 9,
      userId: 9,
      points: 2965,
      level: 13,
      updatedAt: DateTime.now(),
    ),
    GamificationModel(
      gamificationId: 10,
      userId: 10,
      points: 2120,
      level: 10,
      updatedAt: DateTime.now(),
    ),
  ];

  // ==================== TRANSACTIONS ====================
  static final List<TransactionModel> transactions = [
    TransactionModel(
      transactionId: 1,
      itemId: 1,
      sharerId: 1,
      receiverId: 2,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+1',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
      confirmedAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    TransactionModel(
      transactionId: 2,
      itemId: 2,
      sharerId: 2,
      receiverId: 3,
      status: 'pending',
      paymentVerified: false,
      createdAt: DateTime.now().subtract(Duration(hours: 48)),
    ),
    TransactionModel(
      transactionId: 3,
      itemId: 3,
      sharerId: 3,
      receiverId: 4,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+2',
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      confirmedAt: DateTime.now().subtract(Duration(days: 4)),
    ),
    TransactionModel(
      transactionId: 4,
      itemId: 5,
      sharerId: 5,
      receiverId: 1,
      status: 'verified',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+3',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
      confirmedAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
    TransactionModel(
      transactionId: 5,
      itemId: 6,
      sharerId: 1,
      receiverId: 3,
      status: 'completed',
      paymentVerified: true,
      proofImage: 'https://via.placeholder.com/300?text=Payment+Proof+4',
      createdAt: DateTime.now().subtract(Duration(days: 7)),
      confirmedAt: DateTime.now().subtract(Duration(days: 6)),
    ),
  ];

  // ==================== ITEM INTERESTS ====================
  static final List<ItemInterestModel> itemInterests = [
    ItemInterestModel(
      interestId: 1,
      itemId: 1,
      userId: 2,
      reason: 'Cần giày chạy bộ mới',
      status: 'accepted',
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    ItemInterestModel(
      interestId: 2,
      itemId: 1,
      userId: 3,
      reason: 'Thích style của giày này',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(days: 1)),
    ),
    ItemInterestModel(
      interestId: 3,
      itemId: 2,
      userId: 4,
      reason: 'Tìm áo thun màu đen',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 24)),
    ),
    ItemInterestModel(
      interestId: 4,
      itemId: 3,
      userId: 1,
      reason: 'Cần sách học dạy con',
      status: 'accepted',
      createdAt: DateTime.now().subtract(Duration(days: 3)),
    ),
    ItemInterestModel(
      interestId: 5,
      itemId: 4,
      userId: 5,
      reason: 'Tìm ghế ăn cơm rẻ',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 36)),
    ),
    ItemInterestModel(
      interestId: 6,
      itemId: 5,
      userId: 2,
      reason: 'Cần laptop để học lập trình',
      status: 'interested',
      createdAt: DateTime.now().subtract(Duration(hours: 12)),
    ),
  ];

  // ==================== NOTIFICATIONS ====================
  // Notifications are now fetched from API via NotificationApiService
  // Mock data removed - using real database data instead
  static final List<NotificationModel> notifications = [];

  // ==================== USER BADGES ====================
  static final List<UserBadgeModel> userBadges = [
    UserBadgeModel(
      userBadgeId: 1,
      userId: 1,
      badgeId: 1,
      earnedAt: DateTime(2023, 6, 20),
    ),
    UserBadgeModel(
      userBadgeId: 2,
      userId: 1,
      badgeId: 2,
      earnedAt: DateTime(2023, 9, 15),
    ),
    UserBadgeModel(
      userBadgeId: 3,
      userId: 1,
      badgeId: 3,
      earnedAt: DateTime(2024, 1, 10),
    ),
    UserBadgeModel(
      userBadgeId: 4,
      userId: 2,
      badgeId: 1,
      earnedAt: DateTime(2023, 7, 25),
    ),
    UserBadgeModel(
      userBadgeId: 5,
      userId: 2,
      badgeId: 5,
      earnedAt: DateTime(2023, 12, 5),
    ),
    UserBadgeModel(
      userBadgeId: 6,
      userId: 4,
      badgeId: 1,
      earnedAt: DateTime(2023, 9, 10),
    ),
    UserBadgeModel(
      userBadgeId: 7,
      userId: 6,
      badgeId: 2,
      earnedAt: DateTime(2023, 11, 20),
    ),
    UserBadgeModel(
      userBadgeId: 8,
      userId: 6,
      badgeId: 3,
      earnedAt: DateTime(2024, 1, 30),
    ),
  ];

  /// Hàm trợ giúp: Lấy user theo ID
  static UserModel? getUserById(int userId) {
    try {
      return users.firstWhere((u) => u.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy item theo ID
  static ItemModel? getItemById(int itemId) {
    try {
      return items.firstWhere((i) => i.itemId == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy category theo ID
  static CategoryModel? getCategoryById(int categoryId) {
    try {
      return categories.firstWhere((c) => c.categoryId == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy location theo ID
  static LocationModel? getLocationById(int locationId) {
    try {
      return locations.firstWhere((l) => l.locationId == locationId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy badge theo ID
  static BadgeModel? getBadgeById(int badgeId) {
    try {
      return badges.firstWhere((b) => b.badgeId == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy danh sách item của user
  static List<ItemModel> getItemsByUserId(int userId) {
    return items.where((i) => i.userId == userId).toList();
  }

  /// Hàm trợ giúp: Lấy danh sách tin nhắn của user
  static List<MessageModel> getMessagesByUserId(int userId) {
    return messages
        .where((m) => m.senderId == userId || m.receiverId == userId)
        .toList();
  }

  /// Hàm trợ giúp: Lấy gamification của user
  static GamificationModel? getGamificationByUserId(int userId) {
    try {
      return gamifications.firstWhere((g) => g.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Hàm trợ giúp: Lấy badges của user
  static List<BadgeModel> getBadgesByUserId(int userId) {
    final userBadgeList =
        userBadges.where((ub) => ub.userId == userId).toList();
    return userBadgeList
        .map((ub) => getBadgeById(ub.badgeId))
        .whereType<BadgeModel>()
        .toList();
  }

  /// Hàm trợ giúp: Lấy notifications của user
  /// Note: Notifications are now fetched from API via NotificationApiService
  static List<NotificationModel> getNotificationsByUserId(int userId) {
    return notifications.where((n) => n.userId == userId).toList();
  }

  /// Hàm trợ giúp: Đếm unread notifications
  /// Note: Notifications are now fetched from API via NotificationApiService
  static int getUnreadNotificationCount(int userId) {
    return notifications
        .where((n) => n.userId == userId && !n.readStatus)
        .length;
  }
}
