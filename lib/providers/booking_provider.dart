import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../repositories/booking_repository.dart';

class BookingNotifier extends AsyncNotifier<List<BookingModel>> {
  @override
  Future<List<BookingModel>> build() async {
    return _fetchBookings();
  }

  Future<List<BookingModel>> _fetchBookings() async {
    final repository = ref.read(bookingRepositoryProvider);
    return await repository.getBookings();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBookings());
  }

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    final repository = ref.read(bookingRepositoryProvider);
    final newBooking = await repository.createBooking(bookingData);
    
    // Update local cache
    if (state.hasValue) {
      state = AsyncValue.data([newBooking, ...state.value!]);
    }
  }

  Future<void> updateBookingStatus(int id, String newStatus) async {
    final repository = ref.read(bookingRepositoryProvider);
    
    switch (newStatus) {
      case 'accepted':
        await repository.acceptBooking(id);
        break;
      case 'rejected':
        await repository.rejectBooking(id);
        break;
      case 'completed':
        await repository.completeBooking(id);
        break;
      case 'cancelled':
        await repository.cancelBooking(id);
        break;
      default:
        throw Exception('Invalid booking status update.');
    }

    // Update local cache
    if (state.hasValue) {
      final updatedList = state.value!.map((booking) {
        if (booking.id == id) {
          return booking.copyWith(bookingStatus: newStatus);
        }
        return booking;
      }).toList();
      state = AsyncValue.data(updatedList);
    }
  }
}

final bookingNotifierProvider = AsyncNotifierProvider<BookingNotifier, List<BookingModel>>(() {
  return BookingNotifier();
});

final upcomingBookingsProvider = FutureProvider.autoDispose<List<BookingModel>>((ref) async {
  final repository = ref.watch(bookingRepositoryProvider);
  return await repository.getUpcomingBookings();
});
