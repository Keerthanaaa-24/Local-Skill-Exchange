import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_skill_exchange/screens/explore_screen.dart';
import 'package:local_skill_exchange/models/skill_model.dart';
import 'package:local_skill_exchange/providers/skill_provider.dart';

void main() {
  testWidgets('ExploreScreen renders categories and filters skills', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockSkills = [
      SkillModel(
        id: 1,
        title: 'Python Programming',
        description: 'Learn Python fundamentals',
        categoryName: 'Programming & Technology',
        ownerId: 1,
        ownerName: 'Alice',
      ),
      SkillModel(
        id: 2,
        title: 'Hindi Language',
        description: 'Learn Hindi speaking',
        categoryName: 'Languages',
        ownerId: 2,
        ownerName: 'Raj',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          skillCategoryCountsProvider.overrideWith((ref) async => {
            'All': 1607,
            'Academics': 93,
            'Languages': 59,
            'Programming & Technology': 492,
            'Professional Skills': 193,
            'Creative Skills': 392,
            'Practical / Life Skills': 378,
          }),
          filteredSkillsNotifierProvider.overrideWith(
            () => _MockFilteredSkillsNotifier(mockSkills),
          ),
        ],
        child: const MaterialApp(
          home: ExploreScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify TabBar and Title
    expect(find.text('Smart Skill Discovery'), findsOneWidget);
    expect(find.text('Discover Skills'), findsOneWidget);

    // Verify Category Chips
    expect(find.text('All (1607)'), findsOneWidget);
    expect(find.text('Academics (93)'), findsOneWidget);
    expect(find.text('Languages (59)'), findsOneWidget);
    expect(find.text('Programming & Technology (492)'), findsOneWidget);
    expect(find.text('Professional Skills (193)'), findsOneWidget);

    // Scroll to see remaining chips in the horizontal list
    await tester.drag(find.text('Programming & Technology (492)'), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.text('Creative Skills (392)'), findsOneWidget);
    expect(find.text('Practical / Life Skills (378)'), findsOneWidget);

    // Verify Search Bar
    expect(find.byType(TextField), findsOneWidget);
  });
}

class _MockFilteredSkillsNotifier extends FilteredSkillsNotifier {
  final List<SkillModel> _skills;
  _MockFilteredSkillsNotifier(this._skills);

  @override
  Future<List<SkillModel>> build(SkillFilterParam arg) async {
    return _skills;
  }
}
