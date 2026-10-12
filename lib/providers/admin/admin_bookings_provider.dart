import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/booking_model.dart';
import '../../services/api_client.dart';

class AdminBookingsState {
  final bool isLoading;
  final List<BookingModel> bookings;
  final String? errorMessage;
  final bool hasMore;

  const AdminBookingsState({
    this.isLoading = false,
    this.bookings = const [],
    this.errorMessage,
    this.hasMore = false,
  });

  AdminBookingsState copyWith({
    bool? isLoading,
    List<BookingModel>? bookings,
    String? errorMessage,
    bool? hasMore,
  }) {
    return AdminBookingsState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminBookingsNotifier extends AutoDisposeAsyncNotifier<AdminBookingsState> {
  static const int _pageSize = 20;
  int _skip = 0;
  String? _search;

  @override
  Future<AdminBookingsState> build() async {
    // Indicate loading before fetching data
    state = const AsyncLoading();
    _skip = 0;
    return _fetchData();
  }

  // Expose a load() method for callers that expect it
  Future<void> load() async {
    await refresh();
  }


  Future<AdminBookingsState> _fetchData() async {
    try {
      final queryParams = {
        'skip': _skip.toString(),
        'limit': _pageSize.toString(),
        if (_search != null && _search!.isNotEmpty) 'search': _search!,
      };
      final response = await apiClient.dio.get('/admin/bookings', queryParameters: queryParams);
      final List data = response.data as List;
      final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
      final hasMore = bookings.length == _pageSize;
      return AdminBookingsState(isLoading: false, bookings: bookings, hasMore: hasMore);
    } catch (e) {
      return AdminBookingsState(isLoading: false, bookings: [], errorMessage: e.toString(), hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (state.value == null || !state.value!.hasMore || state.value!.isLoading) return;
    
    state = AsyncData(state.value!.copyWith(isLoading: true));
    
    _skip += _pageSize;
    final newState = await _fetchData();
    
    final combined = [...state.value!.bookings, ...newState.bookings];
    state = AsyncData(AdminBookingsState(
      isLoading: false, 
      bookings: combined, 
      hasMore: newState.hasMore
    ));
  }

  Future<void> refresh() async {
    _skip = 0;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  Future<void> search(String term) async {
    _search = term;
    await refresh();
  }
}

final adminBookingsProvider = AutoDisposeAsyncNotifierProvider<AdminBookingsNotifier, AdminBookingsState>(() => AdminBookingsNotifier());
