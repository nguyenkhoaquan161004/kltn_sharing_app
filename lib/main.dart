import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'data/services/fcm_service.dart'
    show FCMService, backgroundMessageHandler;
import 'data/services/location_service.dart';
import 'data/services/message_notification_service.dart';
import 'data/services/firebase_debug_service.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_routes.dart';
import 'routes/app_router.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/item_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/gamification_provider.dart';
import 'data/providers/category_provider.dart';
import 'data/providers/location_provider.dart';
import 'data/providers/recommendation_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/order_provider.dart';
import 'data/providers/websocket_provider.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/item_api_service.dart';
import 'data/services/user_api_service.dart';
import 'data/services/gamification_api_service.dart';
import 'data/services/category_api_service.dart';
import 'data/services/recommendation_api_service.dart';
import 'data/services/notification_api_service.dart';
import 'data/services/cart_api_service.dart';
import 'data/services/transaction_api_service.dart';
import 'data/services/message_api_service.dart';
import 'data/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Location Service first
  try {
    await LocationService().initialize();
    print('[Main] ✅ Location service initialized');
  } catch (e) {
    print('[Main] ⚠️  Location service initialization error: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[Main] ✅ Firebase initialized');
  } catch (e) {
    print('[Main] ⚠️  Firebase initialization error: $e');
  }

  // Register background message handler BEFORE initializing FCM
  try {
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
    print('[Main] ✅ Background message handler registered');
  } catch (e) {
    print('[Main] ⚠️  Failed to register background handler: $e');
  }

  // Initialize FCM
  try {
    await FCMService().initialize();
    print('[Main] ✅ FCM service initialized');
  } catch (e) {
    print('[Main] ⚠️  FCM initialization error: $e');
  }

  // Initialize Message Notification Service for real-time messaging
  try {
    await MessageNotificationService().initialize();
    print('[Main] ✅ Message notification service initialized');
  } catch (e) {
    print('[Main] ⚠️  Message notification service initialization error: $e');
  }

  // Print Firebase debug info
  print('\n');
  print('═' * 60);
  print('🚀 APP INITIALIZED - Running Firebase Debug Check...');
  print('═' * 60);
  FirebaseDebugService.printFullDebugInfo();

  AppConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth API Service
        Provider<AuthApiService>(
          create: (_) => AuthApiService(),
        ),
        // User API Service (created before AuthProvider so it can be injected)
        Provider<UserApiService>(
          create: (_) => UserApiService(),
        ),
        // Auth Provider
        ChangeNotifierProxyProvider2<AuthApiService, UserApiService,
            AuthProvider>(
          create: (context) => AuthProvider(
            authApiService: context.read<AuthApiService>(),
            userApiService: context.read<UserApiService>(),
          ),
          update: (context, authApiService, userApiService, previous) =>
              previous ??
              AuthProvider(
                authApiService: authApiService,
                userApiService: userApiService,
              ),
        ),
        // Item API Service with token refresh callback
        Provider<ItemApiService>(
          create: (context) => ItemApiService(),
        ),
        // Item Provider
        ChangeNotifierProxyProvider<ItemApiService, ItemProvider>(
          create: (context) {
            final itemApiService = context.read<ItemApiService>();
            return ItemProvider(itemApiService: itemApiService);
          },
          update: (context, itemApiService, previous) {
            return previous ?? ItemProvider(itemApiService: itemApiService);
          },
        ),
        // User API Service
        Provider<UserApiService>(
          create: (context) => UserApiService(),
        ),
        // User Provider
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        // Gamification API Service
        Provider<GamificationApiService>(
          create: (context) => GamificationApiService(),
        ),
        // Gamification Provider
        ChangeNotifierProvider<GamificationProvider>(
          create: (_) => GamificationProvider(
            gamificationApiService: _.read<GamificationApiService>(),
          ),
        ),
        // Category API Service
        Provider<CategoryApiService>(
          create: (context) => CategoryApiService(),
        ),
        // Category Provider
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(
            _.read<CategoryApiService>(),
          ),
        ),
        // Location Provider
        ChangeNotifierProvider<LocationProvider>(
          create: (_) => LocationProvider(),
        ),
        // Recommendation API Service
        Provider<RecommendationApiService>(
          create: (context) => RecommendationApiService(),
        ),
        // Recommendation Provider
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => RecommendationProvider(
            apiService: _.read<RecommendationApiService>(),
          ),
        ),
        // Notification API Service
        Provider<NotificationApiService>(
          create: (context) => NotificationApiService(),
        ),
        // Notification Provider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        // Cart API Service
        Provider<CartApiService>(
          create: (context) => CartApiService(),
        ),
        // Transaction API Service
        Provider<TransactionApiService>(
          create: (context) => TransactionApiService(),
        ),
        // Message API Service
        Provider<MessageApiService>(
          create: (context) => MessageApiService(),
        ),
        // WebSocket Provider for real-time messaging
        ChangeNotifierProvider<WebSocketProvider>(
          create: (_) => WebSocketProvider(),
        ),
        // Order Provider - initialize with auth token and load order count
        ChangeNotifierProxyProvider2<AuthProvider, TransactionApiService,
            OrderProvider>(
          create: (context) {
            final transactionApiService = context.read<TransactionApiService>();
            final cartApiService = context.read<CartApiService>();
            final orderProvider = OrderProvider(
              transactionApiService: transactionApiService,
              cartApiService: cartApiService,
            );
            final authProvider = context.read<AuthProvider>();
            if (authProvider.accessToken != null) {
              orderProvider.setAuthToken(authProvider.accessToken!);
              orderProvider.loadOrderCount(); // Load once at app startup
            }
            return orderProvider;
          },
          update: (context, authProvider, transactionApiService, previous) {
            if (previous != null && authProvider.accessToken != null) {
              previous.setAuthToken(authProvider.accessToken!);
              // loadOrderCount is already called in create, only update if token changed
              if (previous.orderCount == 0) {
                previous.loadOrderCount();
              }
            }
            return previous ??
                OrderProvider(
                  transactionApiService: context.read<TransactionApiService>(),
                  cartApiService: context.read<CartApiService>(),
                );
          },
        ),
      ],
      child: _AppInitializer(
        child: MaterialApp.router(
          title: 'KLTN Sharing App',
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

/// Initialize app and restore session
class _AppInitializer extends StatefulWidget {
  final Widget child;

  const _AppInitializer({required this.child});

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait a moment for providers to be ready
      await Future.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        _authProvider = context.read<AuthProvider>();

        // Add listener to detect token expiration/logout
        _authProvider.addListener(_onAuthStateChanged);

        print('[AppInitializer] 🔄 Restoring session...');

        // Restore session with timeout to prevent hang
        try {
          await _authProvider.restoreSession().timeout(
            const Duration(seconds: 45),
            onTimeout: () {
              print('[AppInitializer] ⏱️  Session restoration timeout');
            },
          );
          print('[AppInitializer] ✅ Session restoration complete');
        } catch (e) {
          print('[AppInitializer] ⚠️  Session restoration error: $e');
        }

        // Load user profile if user is logged in
        if (_authProvider.isLoggedIn && _authProvider.accessToken != null) {
          try {
            print('[AppInitializer] 🔄 Loading user profile...');
            final userProvider = context.read<UserProvider>();
            userProvider.setAuthToken(_authProvider.accessToken!);
            await userProvider.loadCurrentUser().timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                print('[AppInitializer] ⏱️  User profile loading timeout');
              },
            );
            print('[AppInitializer] ✅ User profile loaded');
          } catch (e) {
            print('[AppInitializer] ⚠️  Failed to load user profile: $e');
            // Don't fail the initialization if profile fails to load
          }
        }
      }
    } catch (e) {
      print('[AppInitializer] ❌ Error initializing app: $e');
    }
  }

  /// Listen to auth state changes and redirect to login if logged out
  void _onAuthStateChanged() {
    print(
        '[AppInitializer] 🔔 Auth state changed. isLoggedIn: ${_authProvider.isLoggedIn}');

    if (!_authProvider.isLoggedIn && mounted) {
      print(
          '[AppInitializer] ⚠️  Token expired/cleared, redirecting to login...');

      // Use a small delay to ensure state update completes
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          // Force navigate to login
          final router = GoRouter.of(context);
          router.go(AppRoutes.login);
        }
      });
    }
  }

  @override
  void dispose() {
    try {
      _authProvider.removeListener(_onAuthStateChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
