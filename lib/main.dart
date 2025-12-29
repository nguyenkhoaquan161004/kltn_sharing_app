import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/services/fcm_service.dart'
    show FCMService, backgroundMessageHandler;
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
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
        ProxyProvider<AuthProvider, ItemApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = ItemApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? ItemApiService();
          },
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
        // User API Service - Setup token refresh callback
        ProxyProvider<AuthProvider, UserApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = context.read<UserApiService>();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? UserApiService();
          },
        ),
        // User Provider
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        // Gamification API Service
        ProxyProvider<AuthProvider, GamificationApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = GamificationApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? GamificationApiService();
          },
        ),
        // Gamification Provider
        ChangeNotifierProvider<GamificationProvider>(
          create: (_) => GamificationProvider(
            gamificationApiService: _.read<GamificationApiService>(),
          ),
        ),
        // Category API Service
        ProxyProvider<AuthProvider, CategoryApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = CategoryApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? CategoryApiService();
          },
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
        ProxyProvider<AuthProvider, RecommendationApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = RecommendationApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? RecommendationApiService();
          },
        ),
        // Recommendation Provider
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => RecommendationProvider(
            apiService: _.read<RecommendationApiService>(),
          ),
        ),
        // Notification API Service
        ProxyProvider<AuthProvider, NotificationApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = NotificationApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? NotificationApiService();
          },
        ),
        // Notification Provider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        // Cart API Service
        ProxyProvider<AuthProvider, CartApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = CartApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? CartApiService();
          },
        ),
        // Transaction API Service
        ProxyProvider<AuthProvider, TransactionApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = TransactionApiService();
            service.setGetValidTokenCallback(
              () => authProvider.getValidAccessToken(),
            );
            return service;
          },
          update: (context, authProvider, previous) {
            if (previous != null) {
              previous.setGetValidTokenCallback(
                () => authProvider.getValidAccessToken(),
              );
            }
            return previous ?? TransactionApiService();
          },
        ),
        // Message API Service
        ProxyProvider<AuthProvider, MessageApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = MessageApiService();
            // Note: MessageApiService handles token refresh internally
            // via TokenRefreshInterceptor
            return service;
          },
          update: (context, authProvider, previous) {
            return previous ?? MessageApiService();
          },
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
      child: MaterialApp.router(
        title: 'KLTN Sharing App',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
