class Skill {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviews;
  final int price;

  Skill({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.rating,
    required this.reviews,
    required this.price,
  });
}

class Category {
  final String id;
  final String name;
  final String icon;

  Category({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class Teacher {
  final String id;
  final String name;
  final String subject;
  final String avatarUrl;
  final double rating;
  final bool isOnline;

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.avatarUrl,
    required this.rating,
    required this.isOnline,
  });
}

class MockData {
  static final List<Category> categories = [
    Category(id: '1', name: 'Programming', icon: '💻'),
    Category(id: '2', name: 'Design', icon: '🎨'),
    Category(id: '3', name: 'Music', icon: '🎸'),
    Category(id: '4', name: 'Languages', icon: '🗣️'),
    Category(id: '5', name: 'Cooking', icon: '🍳'),
  ];

  static final List<Teacher> popularTeachers = [
    Teacher(
      id: '1',
      name: 'Alice Johnson',
      subject: 'Flutter Expert',
      avatarUrl: '',
      rating: 4.9,
      isOnline: true,
    ),
    Teacher(
      id: '2',
      name: 'Bob Smith',
      subject: 'Data Scientist',
      avatarUrl: '',
      rating: 4.8,
      isOnline: false,
    ),
    Teacher(
      id: '3',
      name: 'Charlie Davis',
      subject: 'Language Coach',
      avatarUrl: '',
      rating: 4.7,
      isOnline: true,
    ),
  ];
}
