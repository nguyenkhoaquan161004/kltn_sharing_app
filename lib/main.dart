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
        // Item API Service
        Provider<ItemApiService>(
          create: (_) => ItemApiService(),
        ),
        // Item Provider
        ChangeNotifierProvider<ItemProvider>(
          create: (_) => ItemProvider(),
        ),
        // User API Service
        Provider<UserApiService>(
          create: (_) => UserApiService(),
        ),
        // User Provider
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
        ),
        // Gamification API Service
        Provider<GamificationApiService>(
          create: (_) => GamificationApiService(),
        ),
        // Gamification Provider
        ChangeNotifierProvider<GamificationProvider>(
          create: (_) => GamificationProvider(
            gamificationApiService: _.read<GamificationApiService>(),
          ),
        ),
        // Category API Service
        Provider<CategoryApiService>(
          create: (_) => CategoryApiService(),
        ),
        // Category Provider
        ChangeNotifierProvider<CategoryProvider>(
          create: (_) => CategoryProvider(
            _.read<CategoryApiService>(),
          ),
        ),
        // Recommendation API Service
        Provider<RecommendationApiService>(
          create: (_) => RecommendationApiService(),
        ),
        // Recommendation Provider
        ChangeNotifierProvider<RecommendationProvider>(
          create: (_) => RecommendationProvider(
            apiService: _.read<RecommendationApiService>(),
          ),
        ),
        // Notification API Service
        Provider<NotificationApiService>(
          create: (_) => NotificationApiService(),
        ),
        // Notification Provider
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
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
