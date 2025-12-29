import 'package:flutter/material.dart';
import '../models/transaction_status.dart';
import '../services/transaction_api_service.dart';
import '../services/cart_api_service.dart';

class OrderProvider extends ChangeNotifier {
  final TransactionApiService _transactionApiService;
  final CartApiService _cartApiService;

  int _orderCount = 0;
  bool _isLoading = false;

  OrderProvider({
    required TransactionApiService transactionApiService,
    required CartApiService cartApiService,
  })  : _transactionApiService = transactionApiService,
        _cartApiService = cartApiService;

  // Getters
  int get orderCount => _orderCount;
  bool get isLoading => _isLoading;

  /// Set auth token for API services
  void setAuthToken(String token) {
    _transactionApiService.setAuthToken(token);
    _cartApiService.setAuthToken(token);
  }

  /// Calculate and cache order count
  /// Should be called once when app initializes
  Future<void> loadOrderCount() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('[OrderProvider] Loading order count...');

      // Get transactions
      final transactions = await _transactionApiService.getMyTransactions();
      print('[OrderProvider] Got ${transactions.length} transactions');

      // Count ONLY pending + accepted transactions
      int transactionCount = 0;
      for (var transaction in transactions) {
        if (transaction.status == TransactionStatus.pending ||
            transaction.status == TransactionStatus.accepted) {
          transactionCount++;
        }
      }

      print(
          '[OrderProvider] Pending + Accepted transactions: $transactionCount');

      // Get cart items
      final cartItems = await _cartApiService.getCart();
      int cartCount = cartItems.length;

      print('[OrderProvider] Cart items: $cartCount');

      // Set total count
      _orderCount = transactionCount + cartCount;
      _isLoading = false;

      print('[OrderProvider] Total order count: $_orderCount');
      notifyListeners();
    } catch (e) {
      print('[OrderProvider] Error loading order count: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Manually update order count (for real-time updates)
  void setOrderCount(int count) {
    _orderCount = count;
    notifyListeners();
  }

  /// Increment order count
  void incrementOrderCount() {
    _orderCount++;
    notifyListeners();
  }

  /// Decrement order count
  void decrementOrderCount() {
    if (_orderCount > 0) {
      _orderCount--;
    }
    notifyListeners();
  }
}
