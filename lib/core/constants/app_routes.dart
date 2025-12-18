class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String emailInput = '/email-input';
  static const String emailVerification = '/email-verification';
  static const String terms = '/terms';

  // Main routes
  static const String home = '/home';
  static const String category = '/category';
  static const String search = '/search';
  static const String searchResults = 'results'; // Child route of /search

  // Product routes
  static const String productDetail = '/product/:id';
  static const String createProduct = '/create-product';

  // Order routes
  static const String orders = '/orders';
  static const String orderDetail = '/order/:id';
  static const String cartItemDetail = '/cart-item/:id';

  // Route names for pushNamed
  static const String orderDetailName = 'order-detail';
  static const String cartItemDetailName = 'cart-item-detail';
  static const String searchResultsName = 'search-results';

  // Profile routes
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String userProducts = '/user-products/:userId';

  // Social routes
  static const String messages = '/messages';
  static const String chat = '/chat/:userId';
  static const String leaderboard = '/leaderboard';
  static const String achievements = '/achievements';
  static const String achievementDetail = '/achievement/:id';
  static const String notifications = '/notifications';

  // Helper methods
  static String getProductDetailRoute(String productId) {
    return '/product/$productId';
  }

  static String getOrderDetailRoute(String orderId) {
    return '/order/$orderId';
  }

  static String getCartItemDetailRoute(String itemId) {
    return '/cart-item/$itemId';
  }

  static String getUserProfileRoute(String userId) {
    return '/user/$userId';
  }

  static String getChatRoute(String userId) {
    return '/chat/$userId';
  }

  static String getUserProductsRoute(String userId) {
    return '/user-products/$userId';
  }

  static String getAchievementDetailRoute(String achievementId) {
    return '/achievement/$achievementId';
  }
}
