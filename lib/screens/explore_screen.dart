import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/constants.dart';
import '../core/utils/responsive_utils.dart';
import '../models/user_model.dart';
import '../models/skill_model.dart';
import '../models/recommendation_model.dart';
import '../models/chat_model.dart';
import '../models/community_models.dart';
import '../widgets/section_header.dart';
import '../providers/user_provider.dart';
import '../providers/skill_provider.dart';
import '../providers/community_provider.dart';
import '../core/widgets/custom_avatar.dart';
import '../core/widgets/error_state.dart';
import 'features/mentor_profile_screen.dart';
import 'features/search_filter_screen.dart';
import 'learning/skill_learning_screen.dart';
import 'conversation_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _discoverScrollController = ScrollController();
  Timer? _debounceTimer;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Academics',
    'Languages',
    'Programming & Technology',
    'Professional Skills',
    'Creative Skills',
    'Practical / Life Skills',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _discoverScrollController.addListener(_onDiscoverScroll);
  }

  void _onDiscoverScroll() {
    if (_discoverScrollController.position.pixels >= _discoverScrollController.position.maxScrollExtent - 200) {
      final param = SkillFilterParam(category: _selectedCategory, query: _searchQuery);
      ref.read(filteredSkillsNotifierProvider(param).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _discoverScrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _navigateToMentorProfile(User user) {
    final rec = RecommendationModel(
      mentorId: int.tryParse(user.id) ?? 0,
      mentorName: user.name,
      mentorProfileImage: user.avatarUrl,
      mentorRating: user.rating,
      mentorReviewCount: user.reviews,
      mentorLatitude: user.lat,
      mentorLongitude: user.lng,
      skillId: 1,
      skillTitle: user.title,
      skillDescription: 'Offering ${user.skillsOffered.join(", ")}',
      skillCategory: user.skillsOffered.isNotEmpty ? user.skillsOffered.first : 'General',
      matchScore: 90.0,
      explanation: '${user.distanceKm} km away',
      distanceKm: user.distanceKm,
      rating: user.rating,
      reason: 'Recommended local mentor available for exchange sessions.',
      canLearn: true,
      canTeach: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MentorProfileScreen(recommendation: rec),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Skill Discovery', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search & Mentor Discovery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.school_outlined), text: 'Discover Skills'),
            Tab(icon: Icon(Icons.near_me_outlined), text: 'Nearby Mentors & Map'),
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Community'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoverSkillsTab(context),
          _buildNearbyMentorsTab(context),
          _buildCommunityTab(context),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: DISCOVER SKILLS
  // ==========================================
  Widget _buildDiscoverSkillsTab(BuildContext context) {
    final filterParam = SkillFilterParam(category: _selectedCategory, query: _searchQuery);
    final skillsAsync = ref.watch(filteredSkillsNotifierProvider(filterParam));
    final notifier = ref.read(filteredSkillsNotifierProvider(filterParam).notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: _buildSearchBar(context),
        ),
        _buildCategoryFilters(),
        const SizedBox(height: AppConstants.paddingS),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(skillCategoryCountsProvider);
              await ref.read(filteredSkillsNotifierProvider(filterParam).notifier).refresh();
            },
            child: skillsAsync.when(
              data: (skills) {
                if (skills.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: 350,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 14),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No skills matching "$_searchQuery" in $_selectedCategory'
                                : 'No skills found in $_selectedCategory',
                            style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedCategory != 'All' || _searchQuery.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = 'All';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                if (_discoverScrollController.hasClients) {
                                  _discoverScrollController.jumpTo(0);
                                }
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Show All Skills'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                final colCount = ResponsiveUtils.gridColumnCount(context, mobile: 1, tablet: 2, desktop: 3, largeDesktop: 4);
                final itemCount = skills.length + (notifier.isLoadingMore ? 1 : 0);

                if (colCount == 1) {
                  return ListView.builder(
                    controller: _discoverScrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == skills.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      }
                      return _buildSkillDiscoveryCard(context, skills[index]);
                    },
                  );
                }

                return GridView.builder(
                  controller: _discoverScrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM, vertical: AppConstants.paddingS),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 250,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == skills.length) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return _buildSkillDiscoveryCard(context, skills[index]);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => ErrorStateWidget(
                error: e,
                onRetry: () => ref.read(filteredSkillsNotifierProvider(filterParam).notifier).refresh(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillDiscoveryCard(BuildContext context, SkillModel skill) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: isDark ? theme.cardTheme.color ?? theme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (skill.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          skill.categoryName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 2),
                  Text(
                    skill.rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            skill.description.isNotEmpty
                ? skill.description
                : 'Structured curriculum with lessons, study materials, practice tests, and certification.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              // LEARN ACTION (Self-paced curriculum)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => SkillLearningScreen(skill: skill)),
                  );
                },
                icon: const Icon(Icons.play_circle_outline_rounded, size: 15),
                label: const Text('Learn'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              // OFFER ACTION (Teach this skill)
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(skillsNotifierProvider.notifier).offerSkill(skill.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added "${skill.title}" to your offered skills! You can now teach others and earn credits.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not offer skill: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.school_outlined, size: 14),
                label: const Text('Offer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              // REQUEST ACTION (Find peer mentor)
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await ref.read(skillsNotifierProvider.notifier).requestSkill(skill.id);
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchFilterScreen(initialQuery: skill.title),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.person_search_outlined, size: 14),
                label: const Text('Request'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: NEARBY MENTORS & MAP
  // ==========================================
  Widget _buildNearbyMentorsTab(BuildContext context) {
    final nearbyUsersAsync = ref.watch(nearbyUsersProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppConstants.paddingM, AppConstants.paddingM, AppConstants.paddingM, 0),
          child: SectionHeader(title: 'Interactive Mentor Map'),
        ),
        _buildMapView(context, nearbyUsersAsync),
        const SizedBox(height: AppConstants.paddingM),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
          child: SectionHeader(title: 'Nearby Mentors & Relevance'),
        ),
        nearbyUsersAsync.when(
          data: (users) => _buildNearbyUsersList(context, users),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppConstants.paddingL),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => ErrorStateWidget(
            error: e,
            onRetry: () => ref.refresh(nearbyUsersProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _searchQuery = val.trim();
              });
              if (_discoverScrollController.hasClients) {
                _discoverScrollController.jumpTo(0);
              }
            }
          });
        },
        decoration: InputDecoration(
          hintText: 'Search skills by name or topic...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                    if (_discoverScrollController.hasClients) {
                      _discoverScrollController.jumpTo(0);
                    }
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final theme = Theme.of(context);
    final countsAsync = ref.watch(skillCategoryCountsProvider);
    final countsMap = countsAsync.value ?? {};

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          final count = countsMap[cat];
          final labelText = count != null && count > 0 ? '$cat ($count)' : cat;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labelText),
              selected: isSelected,
              onSelected: (selected) {
                if (_selectedCategory != cat) {
                  setState(() {
                    _selectedCategory = cat;
                  });
                  if (_discoverScrollController.hasClients) {
                    _discoverScrollController.jumpTo(0);
                  }
                }
              },
              backgroundColor: theme.cardTheme.color,
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapView(BuildContext context, AsyncValue<List<User>> nearbyUsersAsync) {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: nearbyUsersAsync.when(
        data: (users) {
          final validUsers = users.where((u) => u.lat != null && u.lng != null).toList();

          if (validUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off_rounded, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('No mentor coordinates available', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final initialCenter = LatLng(validUsers.first.lat!, validUsers.first.lng!);
          final markers = validUsers.map((user) {
            return Marker(
              markerId: MarkerId(user.id),
              position: LatLng(user.lat!, user.lng!),
              infoWindow: InfoWindow(
                title: user.name,
                snippet: '${user.title} • ${user.rating}★ (${user.distanceKm}km)',
                onTap: () => _navigateToMentorProfile(user),
              ),
            );
          }).toSet();

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: initialCenter, zoom: 12.0),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${validUsers.length} Mentors on Map',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
              const SizedBox(height: 8),
              const Text('Failed to load map data', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => ref.refresh(nearbyUsersProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyUsersList(BuildContext context, List<User> users) {
    final theme = Theme.of(context);

    if (users.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(AppConstants.paddingM),
        padding: const EdgeInsets.all(AppConstants.paddingL),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline_rounded, size: 36, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              const Text(
                'No other mentors nearby at the moment',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Add skills in your profile to become a local mentor and inspire other learners!',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final relevanceReason = user.distanceKm <= 10.0
            ? 'Nearby mentor in your area (${user.distanceKm} km away)'
            : 'Top-rated community mentor';

        return InkWell(
          onTap: () => _navigateToMentorProfile(user),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppConstants.paddingM),
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.cardColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CustomAvatar(
                      radius: 26,
                      imageUrl: user.avatarUrl,
                      name: user.name,
                    ),
                    const SizedBox(width: AppConstants.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(user.title, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('${user.rating}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text('${user.distanceKm} km', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _navigateToMentorProfile(user),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Book'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Personalized relevance chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 13, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        relevanceReason,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: COMMUNITY DISCOVERY & ACTIVITY
  // ==========================================
  Widget _buildCommunityTab(BuildContext context) {
    final discoveryAsync = ref.watch(communityDiscoveryProvider);
    final activityAsync = ref.watch(communityActivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(communityDiscoveryProvider);
        ref.invalidate(communityActivityProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
              ),
              child: const Row(
                children: [
                  Icon(Icons.diversity_3_rounded, color: Colors.white, size: 36),
                  SizedBox(width: AppConstants.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skill Exchange Community',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connect with mentors, learning peers, and nearby partners.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingL),

            // Mentors For You
            discoveryAsync.when(
              data: (discovery) => _buildDiscoverySections(context, discovery),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingM),
                  child: Text('Could not load community peers: $e', style: const TextStyle(color: Colors.grey)),
                ),
              ),
            ),

            const SizedBox(height: AppConstants.paddingL),
            // Live Community Feed
            Row(
              children: [
                Icon(Icons.bolt_rounded, color: Colors.amber.shade700, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Live Community Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingS),
            activityAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(AppConstants.paddingL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: Text(
                        'No community activity yet. Be the first to earn a certificate or complete an exchange!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ),
                  );
                }
                return Column(
                  children: activities.take(8).map((act) => _buildActivityCard(context, act)).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.paddingM),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Text('Could not load activity feed: $e', style: const TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySections(BuildContext context, CommunityDiscoveryModel discovery) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (discovery.mentorsForYou.isNotEmpty) ...[
          _buildDiscoveryGroupHeader('People Who Can Teach You', Icons.school_rounded, Colors.indigo),
          const SizedBox(height: AppConstants.paddingS),
          ...discovery.mentorsForYou.take(3).map((peer) => _buildCommunityPeerCard(context, peer, 'Mentor')),
          const SizedBox(height: AppConstants.paddingM),
        ],

        if (discovery.learningPeers.isNotEmpty) ...[
          _buildDiscoveryGroupHeader('Peers Learning Similar Skills', Icons.group_work_rounded, Colors.teal),
          const SizedBox(height: AppConstants.paddingS),
          ...discovery.learningPeers.take(3).map((peer) => _buildCommunityPeerCard(context, peer, 'Peer')),
          const SizedBox(height: AppConstants.paddingM),
        ],

        if (discovery.nearbyPartners.isNotEmpty) ...[
          _buildDiscoveryGroupHeader('Nearby Skill Partners', Icons.near_me_rounded, Colors.orange),
          const SizedBox(height: AppConstants.paddingS),
          ...discovery.nearbyPartners.take(3).map((peer) => _buildCommunityPeerCard(context, peer, 'Partner')),
        ],
      ],
    );
  }

  Widget _buildDiscoveryGroupHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildCommunityPeerCard(BuildContext context, CommunityDiscoveryPeer peer, String badgeLabel) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomAvatar(
                radius: 20,
                imageUrl: peer.avatarUrl,
                name: peer.name,
              ),
              const SizedBox(width: AppConstants.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            peer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                    if (peer.title != null && peer.title!.isNotEmpty)
                      Text(
                        peer.title!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (peer.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hub_rounded, size: 12, color: Colors.teal),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      peer.reason,
                      style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        chatId: peer.userId,
                        chat: ChatModel(
                          chatId: peer.userId,
                          mentorId: peer.userId,
                          learnerId: 1,
                          partnerName: peer.name,
                          partnerAvatar: peer.avatarUrl ?? '',
                          lastMessage: 'Hi ${peer.name}! Let\'s exchange skills.',
                          lastMessageTime: DateTime.now().toIso8601String(),
                          unreadCount: 0,
                          createdAt: DateTime.now().toIso8601String(),
                          updatedAt: DateTime.now().toIso8601String(),
                          isOnline: true,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                label: const Text('Message', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  final rec = RecommendationModel(
                    mentorId: peer.userId,
                    mentorName: peer.name,
                    mentorProfileImage: peer.avatarUrl,
                    mentorRating: peer.rating,
                    mentorReviewCount: peer.reviewCount,
                    mentorLatitude: 12.9716,
                    mentorLongitude: 77.5946,
                    skillId: 1,
                    skillTitle: peer.title ?? 'Community Partner',
                    skillDescription: peer.commonSkill != null ? 'Common skill: ${peer.commonSkill}' : 'Community skill exchange',
                    skillCategory: peer.commonSkill ?? 'General',
                    matchScore: 85.0,
                    explanation: peer.reason,
                    distanceKm: peer.distanceKm ?? 1.0,
                    rating: peer.rating,
                    reason: peer.reason,
                    canLearn: true,
                    canTeach: false,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MentorProfileScreen(recommendation: rec),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline_rounded, size: 14),
                label: const Text('Profile', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, CommunityActivityItem item) {
    IconData icon;
    Color color;
    switch (item.type) {
      case 'certificate':
        icon = Icons.workspace_premium_rounded;
        color = const Color(0xFFD4AF37);
        break;
      case 'path_completed':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'exchange_completed':
        icon = Icons.swap_horiz_rounded;
        color = Colors.teal;
        break;
      case 'review':
        icon = Icons.star_rounded;
        color = Colors.amber;
        break;
      default:
        icon = Icons.celebration_rounded;
        color = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingS),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusM),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          item.description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${item.timestamp.day}/${item.timestamp.month}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }
}
