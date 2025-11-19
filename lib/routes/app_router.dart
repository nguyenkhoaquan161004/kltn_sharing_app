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
import '../presentation/screens/orders/order_detail_processing_screen.dart';
import '../presentation/screens/orders/order_detail_done_screen.dart';
import '../presentation/screens/orders/proof_of_payment_screen.dart';
import '../presentation/screens/profile/store_information_screen.dart';
import '../presentation/screens/sharing/sharing_screen.dart';
import '../core/constants/app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      // Auth routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const WelcomeScreen(),
        name: 'welcome',
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
        name: 'onboarding',
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
        name: 'login',
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
        name: 'register',
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
        name: 'terms',
      ),
      GoRoute(
        path: AppRoutes.emailInput,
        builder: (context, state) => const EmailInputScreen(),
        name: 'email-input',
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
        name: 'email-verification',
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
        name: 'otp',
      ),

      // Main routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        name: 'home',
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
        name: 'search',
      ),
      GoRoute(
        path: AppRoutes.searchResults,
        builder: (context, state) => const SearchResultsScreen(),
        name: 'search-results',
      ),
      GoRoute(
        path: '/filter',
        builder: (context, state) => const FilterScreen(),
        name: 'filter',
      ),

      // Product routes
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) {
          // final productId = state.pathParameters['id'] ?? '';
          return const ProductDetailScreen();
        },
        name: 'product-detail',
      ),
      GoRoute(
        path: '/product-variant',
        builder: (context, state) => const ProductVariantScreen(),
        name: 'product-variant',
      ),

      // Order routes
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const CartAllScreen(),
        name: 'orders',
      ),
      GoRoute(
        path: '/cart-processing',
        builder: (context, state) => const CartProcessingScreen(),
        name: 'cart-processing',
      ),
      GoRoute(
        path: '/cart-done',
        builder: (context, state) => const CartDoneScreen(),
        name: 'cart-done',
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        builder: (context, state) {
          // final orderId = state.pathParameters['id'] ?? '';
          // TODO: Implement OrderDetailScreen
          return const CartAllScreen();
        },
        name: 'order-detail',
      ),
      GoRoute(
        path: '/order-detail-processing/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return OrderDetailProcessingScreen(orderId: orderId);
        },
        name: 'order-detail-processing',
      ),
      GoRoute(
        path: '/order-detail-done/:id',
        builder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return OrderDetailDoneScreen(orderId: orderId);
        },
        name: 'order-detail-done',
      ),
      GoRoute(
        path: '/proof-of-payment/:orderId',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId'] ?? '';
          return ProofOfPaymentScreen(orderId: orderId);
        },
        name: 'proof-of-payment',
      ),

      // Profile routes
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          // TODO: Implement ProfileScreen
          return const StoreInformationScreen();
        },
        name: 'profile',
      ),
      GoRoute(
        path: '/store-information',
        builder: (context, state) => const StoreInformationScreen(),
        name: 'store-information',
      ),
      GoRoute(
        path: '/sharing',
        builder: (context, state) => const SharingScreen(),
        name: 'sharing',
      ),

      // Social routes
      GoRoute(
        path: AppRoutes.messages,
        builder: (context, state) {
          // TODO: Implement MessagesListScreen
          return const HomeScreen();
        },
        name: 'messages',
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          // final userId = state.pathParameters['userId'] ?? '';
          // TODO: Implement ChatScreen
          return const HomeScreen();
        },
        name: 'chat',
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) {
          // TODO: Implement AchievementsScreen
          return const HomeScreen();
        },
        name: 'achievements',
      ),
    ],
  );
}
