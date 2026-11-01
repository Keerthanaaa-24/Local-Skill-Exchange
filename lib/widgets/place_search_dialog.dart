import 'dart:async';
import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';

class PlaceSearchDialog extends StatefulWidget {
  final String? initialQuery;

  const PlaceSearchDialog({super.key, this.initialQuery});

  static Future<GeocodingPlace?> show(BuildContext context, {String? initialQuery}) {
    return showDialog<GeocodingPlace>(
      context: context,
      builder: (_) => PlaceSearchDialog(initialQuery: initialQuery),
    );
  }

  @override
  State<PlaceSearchDialog> createState() => _PlaceSearchDialogState();
}

class _PlaceSearchDialogState extends State<PlaceSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<GeocodingPlace> _places = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _places = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await geocodingServiceProvider.searchPlaces(query);
      if (mounted) {
        setState(() {
          _places = results;
          _isLoading = false;
          if (results.isEmpty) {
            _errorMessage = 'No places found matching "$query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error connecting to place search. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.travel_explore_rounded, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Search Area / City',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'e.g. Indiranagar, Koramangala, London...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                )
              else if (_places.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _places.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final place = _places[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined, color: Colors.redAccent),
                        title: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          place.displayName,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, place),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 36, color: Colors.grey.shade400),
                        const SizedBox(height: 6),
                        Text(
                          'Type a neighborhood, district, or city name',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Powered by OpenStreetMap & Photon',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
