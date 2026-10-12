import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';

class SkillPickerModal extends ConsumerStatefulWidget {
  final String title;
  final Function(String skillName) onSkillSelected;
  final List<String> alreadySelectedSkills;

  const SkillPickerModal({
    super.key,
    required this.title,
    required this.onSkillSelected,
    this.alreadySelectedSkills = const [],
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    List<String> alreadySelectedSkills = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SkillPickerModal(
        title: title,
        alreadySelectedSkills: alreadySelectedSkills,
        onSkillSelected: (skill) {
          Navigator.pop(ctx, skill);
        },
      ),
    );
  }

  @override
  ConsumerState<SkillPickerModal> createState() => _SkillPickerModalState();
}

class _SkillPickerModalState extends ConsumerState<SkillPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchSkills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.dio.get('/skills/categories');
      if (response.statusCode == 200 && response.data is List) {
        if (mounted) {
          setState(() {
            _categories = List<Map<String, dynamic>>.from(response.data);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchSkills({String query = '', String? category}) async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final queryParams = <String, dynamic>{
        'page': 1,
        'limit': 100,
      };
      if (query.isNotEmpty) queryParams['q'] = query;
      if (category != null && category != 'All') queryParams['category'] = category;

      final response = await client.dio.get('/skills/catalog', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List? ?? [];
        if (mounted) {
          setState(() {
            _skills = List<Map<String, dynamic>>.from(data);
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _searchQuery = val.trim();
      _fetchSkills(query: _searchQuery, category: _selectedCategory);
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchSkills(query: _searchQuery, category: category);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppConstants.radiusXL)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search 1,500+ skills (e.g. Python, UI Design, Guitar)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusL),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
              children: [
                _buildCategoryChip('All', _selectedCategory == 'All', primaryColor),
                ..._categories.map((c) {
                  final catName = c['category']?.toString() ?? '';
                  return _buildCategoryChip(catName, _selectedCategory == catName, primaryColor);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Skills List / Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _skills.isEmpty
                    ? _buildEmptyState(primaryColor)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.paddingM),
                        itemCount: _skills.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (ctx, index) {
                          final item = _skills[index];
                          final name = item['name']?.toString() ?? '';
                          final cat = item['category']?.toString() ?? 'General';
                          final isAlreadySelected = widget.alreadySelectedSkills.contains(name);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: primaryColor.withAlpha(25),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isAlreadySelected ? Colors.grey : null,
                              ),
                            ),
                            subtitle: Text(
                              cat,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                            trailing: isAlreadySelected
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : Icon(Icons.add_circle_outline, color: primaryColor, size: 22),
                            onTap: () {
                              widget.onSkillSelected(name);
                            },
                          );
                        },
                      ),
          ),
          // Custom Skill Bar at Bottom
          if (_searchController.text.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFF9FAFB),
                border: Border(top: BorderSide(color: Colors.grey.withAlpha(50))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Can\'t find "${_searchController.text.trim()}"?',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Text('Add it as a custom skill', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                      ),
                      onPressed: () {
                        widget.onSkillSelected(_searchController.text.trim());
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
        selected: isSelected,
        onSelected: (_) => _onCategorySelected(label),
        selectedColor: primaryColor,
        checkmarkColor: Colors.white,
        backgroundColor: Theme.of(context).cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusL)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final query = _searchController.text.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.withAlpha(150)),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'No skills available in this category' : 'No matches found for "$query"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (query.isNotEmpty) ...[
              const Text(
                'You can add this as a new custom skill to your profile.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusM)),
                ),
                onPressed: () {
                  widget.onSkillSelected(query);
                },
                icon: const Icon(Icons.add),
                label: Text('Add "$query"'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
