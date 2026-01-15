// HƯỚNG DẪN SETUP ADMIN DASHBOARD

/*
1. Mở file: lib/main.dart

2. Thêm import:
   import 'package:kltn_sharing_app/presentation/screens/admin/admin_screens.dart';

3. Tìm MaterialApp widget và thêm routes:

   return MaterialApp(
     home: const SplashScreen(),
     routes: {
       // ... existing routes ...
       
       // Admin Routes
       '/admin-login': (context) => const AdminLoginScreen(),
       '/admin-dashboard': (context) => const AdminDashboardScreen(),
       '/admin-users': (context) => const AdminUsersScreen(),
       '/admin-categories': (context) => const AdminCategoriesScreen(),
       '/admin-badges': (context) => const AdminBadgesScreen(),
       '/admin-reports': (context) => const AdminReportsScreen(),
       '/admin-statistics': (context) => const AdminStatisticsScreen(),
     },
   );

4. Để truy cập admin dashboard, sử dụng:
   Navigator.pushNamed(context, '/admin-login');

5. Hoặc từ terminal Flutter:
   - Chạy app bình thường
   - Thay đổi route ở debug console
   - Hoặc trigger từ user interface

CẤU TRÚC THƯ MỤC:

lib/
├── presentation/screens/admin/
│   ├── admin_screens.dart (export file)
│   ├── screens/
│   │   ├── admin_login_screen.dart
│   │   ├── admin_dashboard_screen.dart
│   │   ├── admin_users_screen.dart
│   │   ├── admin_categories_screen.dart
│   │   ├── admin_badges_screen.dart
│   │   ├── admin_reports_screen.dart
│   │   └── admin_statistics_screen.dart
│   └── widgets/
│       └── admin_sidebar.dart
└── data/services/admin/
    └── admin_api_service.dart

BACKEND APIs ĐƯỢC SỬ DỤNG:

1. User Management
   - GET /api/v2/users (list all users)
   - DELETE /api/v2/users/{userId}

2. Category Management
   - GET /api/v2/categories
   - POST /api/v2/categories
   - PUT /api/v2/categories/{categoryId}
   - DELETE /api/v2/categories/{categoryId}

3. Badge Management
   - GET /api/v2/admin/gamification/badges
   - POST /api/v2/admin/gamification/badges
   - PUT /api/v2/admin/gamification/badges/{id}
   - DELETE /api/v2/admin/gamification/badges/{id}

4. Gamification
   - POST /api/v2/gamification/points/add

5. Notifications
   - POST /api/v2/notifications/send

FEATURES ĐÃ IMPLEMENT:

✅ Admin Login (email/password)
✅ Dashboard with quick stats
✅ User Management (view, add points, send notifications, delete)
✅ Category Management (CRUD)
✅ Badge/Achievement Management (CRUD)
✅ Report Handling (view reports, approve/reject)
✅ Statistics Dashboard (transaction stats, revenue stats, charts placeholder)
✅ Sidebar Navigation

FEATURES CẦN THÊM:

⚠️ Charts Integration (fl_chart)
⚠️ Real API calls for statistics
⚠️ User role-based access control
⚠️ Search & Filter functionality
⚠️ Export data to Excel/PDF
⚠️ Advanced analytics
⚠️ Content moderation tools
⚠️ User ban/suspend features

CÁCH CHẠY:

1. Bắt đầu ứng dụng bình thường:
   flutter run

2. Đăng nhập admin:
   - Email: admin@shario.com (hoặc email có ROLE_ADMIN)
   - Password: (mật khẩu của admin)

3. Sau đăng nhập thành công, bạn sẽ được chuyển hướng đến dashboard

KIỂM THỬ:

1. Test Admin Login
2. Test User Management (list, add points, send notifications)
3. Test Category Management (create, edit, delete)
4. Test Badge Management (create, edit, delete)
5. Test Report Handling
6. Test Statistics View

LƯỚI ý:

- Tất cả API calls đã được implement trong AdminApiService
- Token được lưu trong SharedPreferences với key 'admin_access_token'
- Sidebar auto-highlight current page
- Error handling với user-friendly messages
- Loading states cho tất cả API calls

*/
