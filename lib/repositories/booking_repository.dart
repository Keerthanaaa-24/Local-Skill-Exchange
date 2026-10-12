import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/api_client.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

    Future<List<BookingModel>> getBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings/');
      final data = response.data as List;
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }


  Future<List<BookingModel>> getUpcomingBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings/upcoming/');
      final data = response.data as List;
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      // Fallback if endpoint doesn't exist: fetch all and filter
      try {
        final all = await getBookings();
        return all.where((b) => b.bookingStatus == 'pending' || b.bookingStatus == 'accepted').toList();
      } catch (_) {
        throw Exception('Failed to fetch upcoming bookings: $e');
      }
    }
  }

  Future<List<BookingModel>> getCompletedBookings() async {
    try {
      final response = await _apiClient.dio.get('/bookings/completed/');
      final data = response.data as List;
      return data.map((e) => BookingModel.fromJson(e)).toList();
    } catch (e) {
      try {
        final all = await getBookings();
        return all.where((b) => b.bookingStatus == 'completed').toList();
      } catch (_) {
        throw Exception('Failed to fetch completed bookings: $e');
      }
    }
  }

  Future<BookingModel> getBookingById(int id) async {
    try {
      final response = await _apiClient.dio.get('/bookings/$id');
      return BookingModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }

  Future<BookingModel> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiClient.dio.post('/bookings/', data: bookingData);
      return BookingModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  Future<void> cancelBooking(int id) async {
    try {
      await _apiClient.dio.post('/bookings/$id/cancel');
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  Future<void> acceptBooking(int id) async {
    try {
      await _apiClient.dio.post('/bookings/$id/accept');
    } catch (e) {
      throw Exception('Failed to accept booking: $e');
    }
  }

  Future<void> rejectBooking(int id) async {
    try {
      await _apiClient.dio.post('/bookings/$id/reject');
    } catch (e) {
      throw Exception('Failed to reject booking: $e');
    }
  }

  Future<void> completeBooking(int id) async {
    try {
      await _apiClient.dio.post('/bookings/$id/complete');
    } catch (e) {
      throw Exception('Failed to complete booking: $e');
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(apiClient);
});
