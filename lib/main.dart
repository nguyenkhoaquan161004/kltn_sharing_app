import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'routes/app_router.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/item_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/gamification_provider.dart';
import 'data/providers/category_provider.dart';
import 'data/providers/recommendation_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/item_api_service.dart';
import 'data/services/user_api_service.dart';
import 'data/services/gamification_api_service.dart';
import 'data/services/category_api_service.dart';
import 'data/services/recommendation_api_service.dart';
import 'data/services/notification_api_service.dart';
import 'data/services/cart_api_service.dart';
import 'data/services/transaction_api_service.dart';

void main() {
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
        // Auth Provider
        ChangeNotifierProxyProvider<AuthApiService, AuthProvider>(
          create: (context) => AuthProvider(
            authApiService: context.read<AuthApiService>(),
          ),
          update: (context, authApiService, previous) =>
              previous ?? AuthProvider(authApiService: authApiService),
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
        // User API Service
        ProxyProvider<AuthProvider, UserApiService>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final service = UserApiService();
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
      ],
      child: MaterialApp.router(
        title: 'KLTN Sharing App',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
