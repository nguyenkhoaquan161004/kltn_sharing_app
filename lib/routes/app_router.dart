import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/welcome_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/auth/terms_screen.dart';
import '../presentation/screens/auth/email_input_screen.dart';
import '../presentation/screens/auth/email_verification_screen.dart';
import '../presentation/screens/otp_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/search/search_screen.dart';
import '../presentation/screens/search/search_results_screen.dart';
import '../presentation/screens/search/filter_screen.dart';
import '../presentation/screens/product/product_detail_screen.dart';
import '../presentation/screens/product/product_variant_screen.dart';
import '../presentation/screens/orders/cart_all_screen.dart';
import '../presentation/screens/orders/cart_processing_screen.dart';
import '../presentation/screens/orders/cart_done_screen.dart';
import '../presentation/screens/orders/cart_item_detail_screen.dart';
import '../presentation/screens/orders/order_detail_screen.dart';
import '../presentation/screens/orders/order_detail_processing_screen.dart';
import '../presentation/screens/messages/messages_list_screen.dart';
import '../presentation/screens/messages/chat_screen.dart';
import '../presentation/screens/orders/order_detail_done_screen.dart';
import '../presentation/screens/orders/proof_of_payment_screen.dart';
import '../presentation/screens/profile/store_information_screen.dart';
import '../presentation/screens/sharing/sharing_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/profile/user_profile_screen.dart';
import '../presentation/screens/achievements/achievements_list_screen.dart';
import '../presentation/screens/achievements/badges_list_screen.dart';
import '../presentation/screens/leaderboard/leaderboard_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/error/error_404_screen.dart';
import '../core/constants/app_routes.dart';

class AppRouter {
  // Helper function để tạo smooth page transition
  static CustomTransitionPage<T> _buildPageWithTransition<T>({
    required Widget child,
    required GoRouterState state,
    String? name,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      name: name,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide transition từ phải sang trái
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    errorBuilder: (context, state) => const Error404Screen(),
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const WelcomeScreen(), state: state, name: 'welcome'),
        name: 'welcome',
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const OnboardingScreen(), state: state, name: 'onboarding'),
        name: 'onboarding',
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const LoginScreen(), state: state, name: 'login'),
        name: 'login',
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const RegisterScreen(), state: state, name: 'register'),
        name: 'register',
      ),
      GoRoute(
        path: AppRoutes.terms,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const TermsScreen(), state: state, name: 'terms'),
        name: 'terms',
      ),
      GoRoute(
        path: AppRoutes.emailInput,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const EmailInputScreen(), state: state, name: 'email-input'),
        name: 'email-input',
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        pageBuilder: (context, state) {
          final email = state.extra as String?;
          return _buildPageWithTransition(
            child: EmailVerificationScreen(
              email: email ?? '',
            ),
            state: state,
            name: 'email-verification',
          );
        },
        name: 'email-verification',
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const OtpScreen(), state: state, name: 'otp'),
        name: 'otp',
      ),

      // Main routes
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const HomeScreen(), state: state, name: 'home'),
        name: 'home',
      ),
      GoRoute(
        path: AppRoutes.search,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const SearchScreen(), state: state, name: 'search'),
        name: 'search',
        routes: [
          GoRoute(
            path: AppRoutes.searchResults,
            pageBuilder: (context, state) {
              final keyword = state.uri.queryParameters['keyword'] ?? '';
              return _buildPageWithTransition(
                child: SearchResultsScreen(keyword: keyword),
                state: state,
                name: 'search-results',
              );
            },
            name: 'search-results',
          ),
        ],
      ),
      GoRoute(
        path: '/filter',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const FilterScreen(), state: state, name: 'filter'),
        name: 'filter',
      ),

      // Product routes
      GoRoute(
        path: '/item/:id',
        name: 'item-detail',
        pageBuilder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: ProductDetailScreen(productId: itemId),
            state: state,
            name: 'item-detail',
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product-detail',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: ProductDetailScreen(productId: productId),
            state: state,
            name: 'product-detail',
          );
        },
      ),
      GoRoute(
        path: '/product-variant',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const ProductVariantScreen(),
            state: state,
            name: 'product-variant'),
        name: 'product-variant',
      ),

      // Order routes
      GoRoute(
        path: AppRoutes.orders,
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const CartAllScreen(), state: state, name: 'orders'),
        name: 'orders',
      ),
      GoRoute(
        path: '/cart-processing',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const CartProcessingScreen(),
            state: state,
            name: 'cart-processing'),
        name: 'cart-processing',
      ),
      GoRoute(
        path: '/cart-done',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const CartDoneScreen(), state: state, name: 'cart-done'),
        name: 'cart-done',
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        pageBuilder: (context, state) {
          final transactionId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: OrderDetailScreen(transactionId: transactionId),
            state: state,
            name: 'order-detail',
          );
        },
        name: 'order-detail',
      ),
      GoRoute(
        path: AppRoutes.cartItemDetail,
        pageBuilder: (context, state) {
          final itemId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: CartItemDetailScreen(itemId: itemId),
            state: state,
            name: 'cart-item-detail',
          );
        },
        name: 'cart-item-detail',
      ),
      GoRoute(
        path: '/order-detail-processing/:id',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: OrderDetailProcessingScreen(orderId: orderId),
            state: state,
            name: 'order-detail-processing',
          );
        },
        name: 'order-detail-processing',
      ),
      GoRoute(
        path: '/order-detail-done/:id',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return _buildPageWithTransition(
            child: OrderDetailDoneScreen(orderId: orderId),
            state: state,
            name: 'order-detail-done',
          );
        },
        name: 'order-detail-done',
      ),
      GoRoute(
        path: '/proof-of-payment/:orderId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return _buildPageWithTransition(
            child: ProofOfPaymentScreen(orderId: orderId),
            state: state,
            name: 'proof-of-payment',
          );
        },
        name: 'proof-of-payment',
      ),

      // Profile routes
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            child: const ProfileScreen(),
            state: state,
            name: 'profile',
          );
        },
        name: 'profile',
      ),
      GoRoute(
        path: '/user/:userId',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _buildPageWithTransition(
            child: UserProfileScreen(userId: userId),
            state: state,
            name: 'user-profile',
          );
        },
        name: 'user-profile',
      ),
      GoRoute(
        path: '/store-information',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const StoreInformationScreen(),
            state: state,
            name: 'store-information'),
        name: 'store-information',
      ),
      GoRoute(
        path: '/sharing',
        pageBuilder: (context, state) => _buildPageWithTransition(
            child: const SharingScreen(), state: state, name: 'sharing'),
        name: 'sharing',
      ),

      // Social routes
      GoRoute(
        path: AppRoutes.messages,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            child: const MessagesListScreen(),
            state: state,
            name: 'messages',
          );
        },
        name: 'messages',
      ),
      GoRoute(
        path: AppRoutes.chat,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return _buildPageWithTransition(
            child: ChatScreen(userId: userId),
            state: state,
            name: 'chat',
          );
        },
        name: 'chat',
      ),
      GoRoute(
        path: AppRoutes.achievements,
        pageBuilder: (context, state) {
          // TODO: Implement AchievementsScreen
          return _buildPageWithTransition(
            child: const HomeScreen(),
            state: state,
            name: 'achievements',
          );
        },
        name: 'achievements',
      ),
      GoRoute(
        path: '/achievements/list',
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            child: const AchievementsListScreen(),
            state: state,
            name: 'achievements-list',
          );
        },
        name: 'achievements-list',
      ),
      GoRoute(
        path: '/badges/list',
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            child: const BadgesListScreen(),
            state: state,
            name: 'badges-list',
          );
        },
        name: 'badges-list',
      ),
      GoRoute(
        path: AppRoutes.leaderboard,
        pageBuilder: (context, state) {
          // TODO: Implement LeaderboardScreen
          return _buildPageWithTransition(
            child: const LeaderboardScreen(),
            state: state,
            name: 'leaderboard',
          );
        },
        name: 'leaderboard',
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) {
          return _buildPageWithTransition(
            child: const NotificationsScreen(),
            state: state,
            name: 'notifications',
          );
        },
        name: 'notifications',
      ),
    ],
  );
}
