import 'package:shared_preferences/shared_preferences.dart';

/// Service để manage app preferences và flags
class PreferencesService {
  static const String _categoryPreferencesSetupKey =
      'category_preferences_setup';
  static const String _selectedCategoriesKey = 'selected_categories';

  late SharedPreferences _prefs;

  /// Initialize service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Check if user has already setup category preferences
  Future<bool> isCategoryPreferencesSetup() async {
    await _ensureInitialized();
    return _prefs.getBool(_categoryPreferencesSetupKey) ?? false;
  }

  /// Mark category preferences as setup
  Future<void> setCategoryPreferencesSetup(bool value) async {
    await _ensureInitialized();
    await _prefs.setBool(_categoryPreferencesSetupKey, value);
  }

  /// Save selected categories
  Future<void> setSelectedCategories(List<String> categoryIds) async {
    await _ensureInitialized();
    await _prefs.setStringList(_selectedCategoriesKey, categoryIds);
  }

  /// Get selected categories
  Future<List<String>> getSelectedCategories() async {
    await _ensureInitialized();
    return _prefs.getStringList(_selectedCategoriesKey) ?? [];
  }

  /// Clear all preferences when user logs out
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _prefs.remove(_categoryPreferencesSetupKey);
    await _prefs.remove(_selectedCategoriesKey);
  }

  /// Ensure SharedPreferences is initialized
  Future<void> _ensureInitialized() async {
    if (!_prefs.containsKey('initialized')) {
      // If shared preferences is not initialized, reinitialize
      _prefs = await SharedPreferences.getInstance();
    }
  }
}
