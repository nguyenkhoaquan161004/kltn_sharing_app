#!/bin/bash

# Flutter Project Structure Generator for KTLT App
# Usage: bash setup_project.sh

echo "🚀 Creating Flutter project structure for KTLT App..."

# Create main directories
mkdir -p lib/{core/{constants,theme,utils},data/{models,repositories,services},presentation/{screens,widgets},routes}

# Core - Constants
touch lib/core/constants/app_colors.dart
touch lib/core/constants/app_text_styles.dart
touch lib/core/constants/app_routes.dart
touch lib/core/constants/app_assets.dart

# Core - Theme
touch lib/core/theme/app_theme.dart

# Core - Utils
touch lib/core/utils/validators.dart
touch lib/core/utils/formatters.dart
touch lib/core/utils/helpers.dart

# Data - Models
touch lib/data/models/user_model.dart
touch lib/data/models/product_model.dart
touch lib/data/models/category_model.dart
touch lib/data/models/order_model.dart
touch lib/data/models/message_model.dart
touch lib/data/models/achievement_model.dart

# Data - Repositories
touch lib/data/repositories/auth_repository.dart
touch lib/data/repositories/product_repository.dart
touch lib/data/repositories/order_repository.dart
touch lib/data/repositories/user_repository.dart
touch lib/data/repositories/message_repository.dart
touch lib/data/repositories/leaderboard_repository.dart

# Data - Services
touch lib/data/services/api_service.dart
touch lib/data/services/storage_service.dart

# Presentation - Screens - Splash
mkdir -p lib/presentation/screens/splash
touch lib/presentation/screens/splash/splash_screen.dart

# Presentation - Screens - Onboarding
mkdir -p lib/presentation/screens/onboarding/widgets
touch lib/presentation/screens/onboarding/onboarding_screen.dart
touch lib/presentation/screens/onboarding/widgets/onboarding_page.dart

# Presentation - Screens - Auth
mkdir -p lib/presentation/screens/auth
touch lib/presentation/screens/auth/login_screen.dart
touch lib/presentation/screens/auth/register_screen.dart
touch lib/presentation/screens/auth/email_input_screen.dart
touch lib/presentation/screens/auth/email_verification_screen.dart
touch lib/presentation/screens/auth/terms_screen.dart

# Presentation - Screens - Home
mkdir -p lib/presentation/screens/home/widgets
touch lib/presentation/screens/home/home_screen.dart
touch lib/presentation/screens/home/widgets/product_card.dart
touch lib/presentation/screens/home/widgets/category_chip.dart

# Presentation - Screens - Category
mkdir -p lib/presentation/screens/category/widgets
touch lib/presentation/screens/category/category_screen.dart
touch lib/presentation/screens/category/widgets/category_card.dart

# Presentation - Screens - Search
mkdir -p lib/presentation/screens/search/widgets
touch lib/presentation/screens/search/search_screen.dart
touch lib/presentation/screens/search/search_results_screen.dart
touch lib/presentation/screens/search/widgets/search_history_chip.dart
touch lib/presentation/screens/search/widgets/filter_modal.dart

# Presentation - Screens - Product
mkdir -p lib/presentation/screens/product/widgets
touch lib/presentation/screens/product/product_detail_screen.dart
touch lib/presentation/screens/product/create_product_screen.dart
touch lib/presentation/screens/product/widgets/product_image_carousel.dart
touch lib/presentation/screens/product/widgets/product_info_card.dart
touch lib/presentation/screens/product/widgets/order_request_modal.dart

# Presentation - Screens - Orders
mkdir -p lib/presentation/screens/orders/widgets
touch lib/presentation/screens/orders/orders_screen.dart
touch lib/presentation/screens/orders/order_detail_screen.dart
touch lib/presentation/screens/orders/widgets/order_item_card.dart
touch lib/presentation/screens/orders/widgets/order_progress_tracker.dart
touch lib/presentation/screens/orders/widgets/purchase_success_modal.dart

# Presentation - Screens - Profile
mkdir -p lib/presentation/screens/profile/widgets
touch lib/presentation/screens/profile/profile_screen.dart
touch lib/presentation/screens/profile/edit_profile_screen.dart
touch lib/presentation/screens/profile/user_products_screen.dart
touch lib/presentation/screens/profile/widgets/profile_header.dart
touch lib/presentation/screens/profile/widgets/profile_stats.dart
touch lib/presentation/screens/profile/widgets/product_grid.dart

# Presentation - Screens - Achievements
mkdir -p lib/presentation/screens/achievements/widgets
touch lib/presentation/screens/achievements/achievements_screen.dart
touch lib/presentation/screens/achievements/achievement_collection_screen.dart
touch lib/presentation/screens/achievements/widgets/achievement_card.dart
touch lib/presentation/screens/achievements/widgets/achievement_medal.dart

# Presentation - Screens - Leaderboard
mkdir -p lib/presentation/screens/leaderboard/widgets
touch lib/presentation/screens/leaderboard/leaderboard_screen.dart
touch lib/presentation/screens/leaderboard/widgets/podium_widget.dart
touch lib/presentation/screens/leaderboard/widgets/leaderboard_item.dart

# Presentation - Screens - Messages
mkdir -p lib/presentation/screens/messages/widgets
touch lib/presentation/screens/messages/messages_list_screen.dart
touch lib/presentation/screens/messages/chat_screen.dart
touch lib/presentation/screens/messages/widgets/message_bubble.dart
touch lib/presentation/screens/messages/widgets/chat_input.dart
touch lib/presentation/screens/messages/widgets/quick_reply_chip.dart

# Presentation - Widgets (Common)
touch lib/presentation/widgets/custom_button.dart
touch lib/presentation/widgets/custom_text_field.dart
touch lib/presentation/widgets/custom_app_bar.dart
touch lib/presentation/widgets/gradient_button.dart
touch lib/presentation/widgets/pin_input.dart
touch lib/presentation/widgets/loading_indicator.dart
touch lib/presentation/widgets/custom_tab_bar.dart
touch lib/presentation/widgets/badge_widget.dart

# Routes
touch lib/routes/app_router.dart

# Assets directories
mkdir -p assets/{images,icons,fonts}

# Create README for assets
cat > assets/README.md << 'EOF'
# Assets Directory

## Images
- logo.png - App logo "N"
- onboarding_1.png - First onboarding illustration
- onboarding_2.png - Second onboarding illustration
- default_avatar.png - Default user avatar

## Icons
- google_icon.png - Google sign-in icon
- category_*.png - Category icons (books, clothes, food, furniture)
- tab_*.png - Bottom navigation icons
- achievement_*.png - Achievement badges icons

## Fonts
Place custom fonts here if needed
EOF

# Create a basic pubspec.yaml template
cat > pubspec_template.yaml << 'EOF'
name: ktlt_app
description: A Flutter marketplace app for sharing items
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  
  # Navigation
  go_router: ^13.0.0
  
  # Network
  http: ^1.0.0
  dio: ^5.0.0
  
  # Local Storage
  shared_preferences: ^2.0.0
  
  # UI Components
  cached_network_image: ^3.2.0
  shimmer: ^3.0.0
  flutter_svg: ^2.0.0
  
  # Date & Time
  intl: ^0.18.0
  
  # Image Picker
  image_picker: ^1.0.0
  
  # QR Code
  qr_flutter: ^4.1.0
  
  # Carousel
  carousel_slider: ^4.2.0
  
  # Pin Input
  pin_code_fields: ^8.0.0
  
  # Animations
  lottie: ^2.7.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
  
  # fonts:
  #   - family: CustomFont
  #     fonts:
  #       - asset: assets/fonts/CustomFont-Regular.ttf
  #       - asset: assets/fonts/CustomFont-Bold.ttf
  #         weight: 700
EOF

echo "✅ Project structure created successfully!"
echo ""
echo "📁 Directory tree:"
tree -L 3 lib/ 2>/dev/null || find lib -type f | sort

echo ""
echo "📝 Next steps:"
echo "1. Copy the contents of pubspec_template.yaml to your pubspec.yaml"
echo "2. Run: flutter pub get"
echo "3. Start coding! 🚀"
echo ""
echo "💡 Tip: Add your images to assets/images/ and icons to assets/icons/"