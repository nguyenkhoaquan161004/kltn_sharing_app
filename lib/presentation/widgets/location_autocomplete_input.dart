import 'package:flutter/material.dart';
import 'package:kltn_sharing_app/core/theme/app_colors.dart';
import 'package:kltn_sharing_app/data/models/location_model.dart';
import 'package:kltn_sharing_app/data/services/places_service.dart';

class LocationAutocompleteInput extends StatefulWidget {
  final Function(LocationModel) onLocationSelected;
  final VoidCallback? onClear;
  final String? initialValue;

  const LocationAutocompleteInput({
    super.key,
    required this.onLocationSelected,
    this.onClear,
    this.initialValue,
  });

  @override
  State<LocationAutocompleteInput> createState() =>
      _LocationAutocompleteInputState();
}

class _LocationAutocompleteInputState extends State<LocationAutocompleteInput> {
  late TextEditingController _controller;
  List<LocationModel> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await PlacesService.searchPlaces(query);
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('[LocationAutocomplete] Error searching places: $e');
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
    }
  }

  void _selectLocation(LocationModel location) {
    _controller.text = location.name;
    setState(() {
      _showSuggestions = false;
    });
    widget.onLocationSelected(location);
  }

  void _clearSelection() {
    _controller.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input
        TextField(
          controller: _controller,
          onChanged: (value) {
            _searchPlaces(value);
          },
          onTap: () {
            if (_controller.text.isNotEmpty && _suggestions.isNotEmpty) {
              setState(() {
                _showSuggestions = true;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Nhập tên khu vực...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryGreen,
                width: 2,
              ),
            ),
            prefixIcon:
                const Icon(Icons.location_on, color: AppColors.textSecondary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon:
                        const Icon(Icons.clear, color: AppColors.textSecondary),
                    onPressed: _clearSelection,
                  )
                : (_isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCCCCCC)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final location = _suggestions[index];
                return InkWell(
                  onTap: () => _selectLocation(location),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
