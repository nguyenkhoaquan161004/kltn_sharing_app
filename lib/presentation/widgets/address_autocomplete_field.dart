import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/services/address_suggestion_service.dart';

/// Reusable Address Autocomplete Field Widget
/// Provides autocomplete suggestions for addresses with lat/long extraction
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final Function(double latitude, double longitude, String address)
      onAddressSelected; // Callback khi chọn địa chỉ
  final String? initialAddress;
  final TextInputAction textInputAction;
  final int maxLines;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    required this.onAddressSelected,
    this.initialAddress,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
  });

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late FocusNode _focusNode;
  List<LocationPrediction> _suggestions = [];
  bool _showSuggestions = false;
  bool _isSearching = false;
  final _addressService = AddressSuggestionService();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Set initial address if provided
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      widget.controller.text = widget.initialAddress!;
    }

    // Listen to text changes
    widget.controller.addListener(_onAddressChanged);

    // Listen to focus changes
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(_onAddressChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Get address suggestions based on user input
  Future<void> _onAddressChanged() async {
    final query = widget.controller.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear suggestions if less than 3 characters
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Set debounce timer (0.5 - 1s)
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!_isSearching && mounted) {
        setState(() {
          _isSearching = true;
        });

        try {
          // Get location predictions
          final predictions =
              await _addressService.getAddressPredictions(query);

          if (mounted) {
            setState(() {
              _suggestions = predictions;
              _showSuggestions = _suggestions.isNotEmpty;
              _isSearching = false;
            });
          }
        } catch (e) {
          print('[AddressAutocomplete] Error getting suggestions: $e');
          if (mounted) {
            setState(() {
              _suggestions = [];
              _showSuggestions = false;
              _isSearching = false;
            });
          }
        }
      }
    });
  }

  /// Handle suggestion selection
  Future<void> _selectAddress(LocationPrediction prediction) async {
    try {
      widget.controller.text = prediction.displayAddress;

      // Call callback with lat/long
      widget.onAddressSelected(
        prediction.latitude,
        prediction.longitude,
        prediction.displayAddress,
      );

      print(
          '[AddressAutocomplete] Selected: ${prediction.displayAddress} (${prediction.latitude}, ${prediction.longitude})');

      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    } catch (e) {
      print('[AddressAutocomplete] Error selecting address: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: Không thể xác nhận địa chỉ này')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: AppTextStyles.label,
          ),
        if (widget.label.isNotEmpty) const SizedBox(height: 8),

        // Text Field with Autocomplete
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Nhập địa chỉ...',
            filled: true,
            fillColor: AppColors.backgroundGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),

        // Suggestions Dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(
                    suggestion.displayAddress,
                    style: AppTextStyles.secondary14R,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  subtitle: Text(
                    '${suggestion.latitude.toStringAsFixed(4)}, ${suggestion.longitude.toStringAsFixed(4)}',
                    style: AppTextStyles.note12R.copyWith(color: Colors.grey),
                  ),
                  onTap: () => _selectAddress(suggestion),
                  leading: const Icon(Icons.location_on, color: Colors.grey),
                );
              },
            ),
          ),
      ],
    );
  }
}
