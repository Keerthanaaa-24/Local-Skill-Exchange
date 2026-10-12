import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_avatar.dart';
import '../../core/widgets/loading_state.dart';
import '../../core/widgets/error_state.dart';
import '../../providers/skill_provider.dart';
import '../../models/skill_model.dart';
import '../../models/recommendation_model.dart';
import '../learning/skill_learning_screen.dart';
import 'mentor_profile_screen.dart';

class SearchFilterScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const SearchFilterScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  ConsumerState<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends ConsumerState<SearchFilterScreen> {
  double _distanceValue = 50;
  double _creditsValue = 100;
  double _minRating = 0.0;
  String _selectedSort = 'Recommended';
  final Set<String> _selectedCategories = {'All'};
  String _searchQuery = '';
  bool _isMapView = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  GoogleMapController? _mapController;
  Timer? _debounce;

  final List<String> _categories = [
    'All',
    'Technology',
    'Programming',
    'AI & Data',
    'Design',
    'Marketing',
    'Languages',
    'Music',
    'Academic',
    'Fitness',
    'Cooking',
    'Photography',
    'Trades & DIY',
    'Business',
  ];

  final List<String> _sortOptions = ['Recommended', 'Highest Rated', 'Nearest', 'Lowest Price', 'Newest'];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchQuery = widget.initialQuery!.trim();
      _searchController.text = widget.initialQuery!;
    }
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      _selectedCategories.clear();
      _selectedCategories.add(widget.initialCategory!);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      ref.read(skillsNotifierProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.trim();
      });
    });
  }

  bool _matchesCategory(String skillCategory, String filter) {
    final sc = skillCategory.toLowerCase();
    final f = filter.toLowerCase();
    if (f == 'all') return true;
    if (f == 'technology') {
      return sc.contains('programming') || sc.contains('tech') || sc.contains('web') ||
             sc.contains('backend') || sc.contains('mobile') || sc.contains('cloud') ||
             sc.contains('devops') || sc.contains('cyber') || sc.contains('ai') ||
             sc.contains('data') || sc.contains('software');
    }
    if (f == 'programming') {
      return sc.contains('programming') || sc.contains('software') || sc.contains('web') ||
             sc.contains('backend') || sc.contains('mobile');
    }
    if (f == 'ai & data') {
      return sc.contains('ai') || sc.contains('machine learning') || sc.contains('data') ||
             sc.contains('deep learning') || sc.contains('analytics');
    }
    if (f == 'design') {
      return sc.contains('design') || sc.contains('ui') || sc.contains('ux') ||
             sc.contains('graphic') || sc.contains('3d') || sc.contains('art');
    }
    if (f == 'marketing') {
      return sc.contains('marketing') || sc.contains('sales') || sc.contains('advertising') || sc.contains('seo');
    }
    if (f == 'languages') {
      return sc.contains('language') || sc.contains('linguistics') || sc.contains('spanish') ||
             sc.contains('french') || sc.contains('mandarin') || sc.contains('english') ||
             sc.contains('german') || sc.contains('japanese') || sc.contains('korean');
    }
    if (f == 'music') {
      return sc.contains('music') || sc.contains('audio') || sc.contains('instrument') ||
             sc.contains('vocal') || sc.contains('sound') || sc.contains('guitar') || sc.contains('piano');
    }
    if (f == 'academic') {
      return sc.contains('academic') || sc.contains('tutoring') || sc.contains('math') ||
             sc.contains('science') || sc.contains('physics') || sc.contains('chemistry') || sc.contains('calculus');
    }
    if (f == 'fitness') {
      return sc.contains('fitness') || sc.contains('health') || sc.contains('athletic') ||
             sc.contains('wellness') || sc.contains('yoga') || sc.contains('training') || sc.contains('running');
    }
    if (f == 'cooking') {
      return sc.contains('culinary') || sc.contains('cooking') || sc.contains('baking') ||
             sc.contains('beverage') || sc.contains('food') || sc.contains('pastry');
    }
    if (f == 'photography') {
      return sc.contains('photo') || sc.contains('video') || sc.contains('cinematography') || sc.contains('camera');
    }
    if (f == 'trades & diy') {
      return sc.contains('trade') || sc.contains('craft') || sc.contains('diy') ||
             sc.contains('maker') || sc.contains('wood') || sc.contains('repair') || sc.contains('automotive');
    }
    if (f == 'business') {
      return sc.contains('business') || sc.contains('strategy') || sc.contains('finance') ||
             sc.contains('entrepreneurship') || sc.contains('management');
    }
    return sc.contains(f);
  }

  List<SkillModel> _applyFilters(List<SkillModel> skills) {
    var filtered = skills;

    // 1. Multi-Category OR Logic
    if (_selectedCategories.isNotEmpty && !_selectedCategories.contains('All')) {
      filtered = filtered.where((s) {
        final cat = s.categoryName ?? '';
        return _selectedCategories.any((selectedCat) => _matchesCategory(cat, selectedCat));
      }).toList();
    }

    // 2. Search Query (Matching skill title, category, owner name, description)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((s) =>
        s.title.toLowerCase().contains(q) ||
        (s.categoryName?.toLowerCase().contains(q) ?? false) ||
        s.ownerName.toLowerCase().contains(q) ||
        s.description.toLowerCase().contains(q)
      ).toList();
    }

    // 3. Credits Filter
    if (_creditsValue < 100) {
      filtered = filtered.where((s) => s.credits <= _creditsValue).toList();
    }

    // 4. Rating Filter
    if (_minRating > 0.0) {
      filtered = filtered.where((s) => s.rating >= _minRating).toList();
    }

    // 5. Sorting
    if (_selectedSort == 'Highest Rated') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_selectedSort == 'Lowest Price') {
      filtered.sort((a, b) => a.credits.compareTo(b.credits));
    } else if (_selectedSort == 'Newest') {
      filtered.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    }

    return filtered;
  }

  void _onCategoryTapped(String cat) {
    setState(() {
      if (cat == 'All') {
        _selectedCategories.clear();
        _selectedCategories.add('All');
      } else {
        _selectedCategories.remove('All');
        if (_selectedCategories.contains(cat)) {
          _selectedCategories.remove(cat);
        } else {
          _selectedCategories.add(cat);
        }
        if (_selectedCategories.isEmpty) {
          _selectedCategories.add('All');
        }
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedCategories.add('All');
      _creditsValue = 100;
      _distanceValue = 50;
      _minRating = 0.0;
      _selectedSort = 'Recommended';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  bool get _hasActiveFilters {
    return !_selectedCategories.contains('All') ||
           _searchQuery.isNotEmpty ||
           _creditsValue < 100 ||
           _minRating > 0.0 ||
           _selectedSort != 'Recommended';
  }

  void _showMentorModal(SkillModel skill) {
    final rec = RecommendationModel.fromSkill(skill);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomAvatar(radius: 28, imageUrl: skill.ownerProfileImage, name: skill.ownerName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(skill.ownerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(skill.title, style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      Text(' ${skill.rating.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Theme.of(context).primaryColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getExplainableReason(skill),
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'View Mentor Profile & Book Session',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MentorProfileScreen(recommendation: rec),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getExplainableReason(SkillModel skill) {
    if (_searchQuery.isNotEmpty && skill.title.toLowerCase().contains(_searchQuery.toLowerCase())) {
      return 'Matches your requested goal to learn ${skill.title}';
    }
    if (skill.rating >= 4.8) {
      return 'Top-Rated Mentor in ${skill.categoryName ?? "General"} • ${skill.rating}★ Rating';
    }
    return 'Nearby mentor available for peer skill exchange session';
  }

  Set<Marker> _buildMapMarkers(List<SkillModel> skills) {
    final Set<Marker> markers = {};
    for (int i = 0; i < skills.length; i++) {
      final s = skills[i];
      // Generate slight deterministic offset around Bangalore center if coordinates missing
      final double lat = s.latitude ?? (12.9716 + (i * 0.008 * (i % 2 == 0 ? 1 : -1)));
      final double lng = s.longitude ?? (77.5946 + (i * 0.007 * (i % 3 == 0 ? 1 : -1)));

      markers.add(
        Marker(
          markerId: MarkerId('mentor_${s.id}_$i'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: s.ownerName,
            snippet: '${s.title} • ${s.rating}★ (${s.credits} cr)',
            onTap: () => _showMentorModal(s),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            s.rating >= 4.8 ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
          ),
          onTap: () => _showMentorModal(s),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = _searchQuery.isEmpty
        ? ref.watch(skillsNotifierProvider)
        : ref.watch(searchSkillsProvider(_searchQuery));

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _searchQuery.isNotEmpty ? 'Mentors for "$_searchQuery"' : 'Smart Mentor Discovery',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: Icon(_isMapView ? Icons.view_list_rounded : Icons.map_rounded),
              tooltip: _isMapView ? 'Switch to List View' : 'Switch to Map View',
              onPressed: () {
                setState(() {
                  _isMapView = !_isMapView;
                });
              },
            ),
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingS,
            ),
            child: _buildInlineFilters(),
          ),
          Expanded(
            child: searchResultsAsync.when(
              data: (skills) {
                final filteredSkills = _applyFilters(skills);

                if (filteredSkills.isEmpty) {
                  return _buildEmptyState(context);
                }

                if (isDesktop) {
                  // Side-by-side desktop layout: List on Left, Map on Right
                  return Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildSkillListView(filteredSkills),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        flex: 5,
                        child: _buildMapView(filteredSkills),
                      ),
                    ],
                  );
                }

                // Mobile/Tablet responsive layout based on _isMapView toggle
                return _isMapView
                    ? _buildMapView(filteredSkills)
                    : _buildSkillListView(filteredSkills);
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppConstants.paddingM),
                itemCount: 6,
                itemBuilder: (context, index) => const Padding(
                  padding: EdgeInsets.only(bottom: AppConstants.paddingM),
                  child: LoadingSkeletonCard(height: 90),
                ),
              ),
              error: (err, stack) => ErrorStateWidget(
                error: err,
                onRetry: () {
                  if (_searchQuery.isEmpty) {
                    ref.read(skillsNotifierProvider.notifier).refresh();
                  } else {
                    ref.invalidate(searchSkillsProvider(_searchQuery));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillListView(List<SkillModel> filteredSkills) {
    return RefreshIndicator(
      onRefresh: () async {
        if (_searchQuery.isEmpty) {
          await ref.read(skillsNotifierProvider.notifier).refresh();
        } else {
          ref.invalidate(searchSkillsProvider(_searchQuery));
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppConstants.paddingM),
        itemCount: filteredSkills.length + 1,
        itemBuilder: (context, index) {
          if (index == filteredSkills.length) {
            return const SizedBox(height: 60);
          }
          final skill = filteredSkills[index];
          return _buildSearchResultTile(skill);
        },
      ),
    );
  }

  Widget _buildMapView(List<SkillModel> filteredSkills) {
    final markers = _buildMapMarkers(filteredSkills);
    const initialTarget = LatLng(12.9716, 77.5946);

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: initialTarget,
        zoom: 12.0,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final targetSkillTitle = _searchQuery.isNotEmpty ? _searchQuery : 'this skill';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded, size: 64, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No mentors found for "$_searchQuery" nearby'
                  : 'No mentors matching selected filters',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Don\'t worry! You can expand your search distance, connect with online mentors, or start learning with our structured self-paced course.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _distanceValue = 100;
                    });
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Expand Distance (100 km)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _distanceValue = 100;
                      _minRating = 0.0;
                    });
                  },
                  icon: const Icon(Icons.wifi_rounded, size: 16),
                  label: const Text('Explore Online Mentors'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final fallbackSkill = SkillModel(
                      id: 1,
                      title: targetSkillTitle,
                      description: 'Master $targetSkillTitle through interactive lessons, quizzes, and hands-on practice.',
                      categoryName: _selectedCategories.first != 'All' ? _selectedCategories.first : 'General',
                      ownerId: 1,
                      ownerName: 'AI Skill Coach',
                      ownerProfileImage: null,
                      rating: 5.0,
                      reviewCount: 25,
                      credits: 10,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SkillLearningScreen(skill: fallbackSkill),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_rounded, size: 16),
                  label: Text('Explore $targetSkillTitle Course'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset All Search Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search skills (e.g. Python, Hindi, Photography, SQL)...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'More Filters',
                onPressed: _showFilterBottomSheet,
              ),
            ],
          ),
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ).animate().fade().slideY(begin: -0.1);
  }

  Widget _buildInlineFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategories.contains(cat);
          final primaryColor = Theme.of(context).primaryColor;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => _onCategoryTapped(cat),
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primaryColor : Colors.grey.withAlpha(50),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.1);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Advanced Mentor Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingM),
                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Distance Range (km)', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_distanceValue.round()} km', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _distanceValue,
                          min: 1,
                          max: 100,
                          divisions: 99,
                          label: '${_distanceValue.round()} km',
                          onChanged: (val) => setModalState(() => _distanceValue = val),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Max Credits / Session', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_creditsValue.round()} Credits', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _creditsValue,
                          min: 5,
                          max: 100,
                          divisions: 19,
                          label: '${_creditsValue.round()} Credits',
                          onChanged: (val) => setModalState(() => _creditsValue = val),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [0.0, 4.0, 4.5, 5.0].map((r) {
                            final isSel = _minRating == r;
                            return ChoiceChip(
                              label: Text(r == 0.0 ? 'All Ratings' : '$r★ & Up'),
                              selected: isSel,
                              onSelected: (val) => setModalState(() => _minRating = r),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppConstants.paddingM),
                        const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sortOptions.map((opt) {
                            return ChoiceChip(
                              label: Text(opt),
                              selected: _selectedSort == opt,
                              onSelected: (val) => setModalState(() => _selectedSort = opt),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  CustomButton(
                    text: 'Apply Filters',
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResultTile(SkillModel skill) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MentorProfileScreen(
              recommendation: RecommendationModel.fromSkill(skill),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomAvatar(
                  radius: 28,
                  imageUrl: skill.ownerProfileImage,
                  name: skill.ownerName,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skill.categoryName ?? 'General',
                              style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'by ${skill.ownerName}',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          Text(' ${skill.rating.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Text(' (${skill.reviewCount})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 12),
                          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                          const Text(' 2.5 km', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Icon(Icons.stars_rounded, color: primaryColor, size: 22),
                    const SizedBox(height: 2),
                    Text(
                      '${skill.credits} cr',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: primaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getExplainableReason(skill),
                      style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
    );
  }
}
