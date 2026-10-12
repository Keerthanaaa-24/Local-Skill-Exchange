import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/review_model.dart';
import '../../services/api_client.dart';

class AdminReviewsState {
  final bool isLoading;
  final List<ReviewModel> reviews;
  final String? errorMessage;
  final bool hasMore;

  const AdminReviewsState({
    this.isLoading = false,
    this.reviews = const [],
    this.errorMessage,
    this.hasMore = false,
  });

  AdminReviewsState copyWith({
    bool? isLoading,
    List<ReviewModel>? reviews,
    String? errorMessage,
    bool? hasMore,
  }) {
    return AdminReviewsState(
      isLoading: isLoading ?? this.isLoading,
      reviews: reviews ?? this.reviews,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminReviewsNotifier extends AutoDisposeAsyncNotifier<AdminReviewsState> {
  static const int _pageSize = 20;
  int _skip = 0;
  String? _search;

  @override
  Future<AdminReviewsState> build() async {
    // Indicate loading before fetching data
    state = const AsyncLoading();
    _skip = 0;
    return _load();
  }

  // Expose a load() method for callers that expect it
  Future<void> load() async {
    await refresh();
  }


  Future<AdminReviewsState> _load() async {
    try {
      final queryParams = {
        'skip': _skip.toString(),
        'limit': _pageSize.toString(),
        if (_search != null && _search!.isNotEmpty) 'search': _search!,
      };
      final response = await apiClient.dio.get('/admin/reviews', queryParameters: queryParams);
      final List data = response.data as List;
      final reviews = data.map((e) => ReviewModel.fromJson(e)).toList();
      final hasMore = reviews.length == _pageSize;
      return AdminReviewsState(isLoading: false, reviews: reviews, hasMore: hasMore);
    } catch (e) {
      return AdminReviewsState(isLoading: false, reviews: [], errorMessage: e.toString(), hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (state.value == null || !state.value!.hasMore || state.value!.isLoading) return;
    state = AsyncData(state.value!.copyWith(isLoading: true));
    _skip += _pageSize;
    final newState = await _load();
    final combined = [...state.value!.reviews, ...newState.reviews];
    state = AsyncData(AdminReviewsState(isLoading: false, reviews: combined, hasMore: newState.hasMore));
  }

  Future<void> refresh() async {
    _skip = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load());
  }

  Future<void> search(String term) async {
    _search = term;
    await refresh();
  }
}

final adminReviewsProvider = AutoDisposeAsyncNotifierProvider<AdminReviewsNotifier, AdminReviewsState>(() => AdminReviewsNotifier());
