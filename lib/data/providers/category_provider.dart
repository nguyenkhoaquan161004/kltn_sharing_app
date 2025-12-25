import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/data/models/category_response_model.dart';
import 'package:kltn_sharing_app/data/services/category_api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryApiService _categoryApiService;

  List<CategoryDto> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  CategoryProvider(this._categoryApiService);

  List<CategoryDto> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryApiService.getAllCategories();
      print('[CategoryProvider] Loaded ${_categories.length} categories');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      print('[CategoryProvider] Error: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
