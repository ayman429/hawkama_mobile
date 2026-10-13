import '../../../core/config.dart';
import '../../../core/mock/mock_catalog.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/network/json_parse.dart';
import '../../../core/network/result.dart';
import '../../../l10n/strings.dart';
import '../models/booking.dart';
import '../models/consultant.dart';
import '../models/quote.dart';
import '../models/slot.dart';

class BookingRepository {
  BookingRepository(this._api);

  final ApiClient _api;

  Future<Result<List<Consultant>>> consultants({String? specialization}) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockConsultants;
      }
      return asList(
        await _api.get(Endpoints.consultants, {
          if (specialization != null) 'specialization': specialization,
        }),
        Consultant.fromJson,
      );
    });
  }

  Future<Result<List<String>>> availableDates(int consultantId, String month) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockAvailableDates;
      }
      final data = asMap(await _api.get(
        Endpoints.availableDates(consultantId),
        {'month': month},
      ));
      return data['dates'] is List
          ? (data['dates'] as List).map((item) => '$item').toList()
          : const [];
    });
  }

  Future<Result<List<Slot>>> slots(int consultantId, String date) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockSlots;
      }
      final data = asMap(await _api.get(
        Endpoints.slots(consultantId),
        {'date': date},
      ));
      return asList(data['slots'], Slot.fromJson);
    });
  }

  Future<Result<Quote>> quote({
    required int packageId,
    int? consultantId,
    String? date,
    String? time,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 250));
        return Quote(
          amount: mockPackages.first.price,
          amountFormatted: mockPackages.first.priceFormatted,
          requiresPayment: true,
        );
      }
      return Quote.fromJson(asMap(await _api.post(Endpoints.quote, {
        'package_id': packageId,
        if (consultantId != null) 'consultant_id': consultantId,
        if (date != null) 'date': date,
        if (time != null) 'time': time,
      })));
    });
  }

  Future<Result<BookingCreateResult>> createBooking({
    required int packageId,
    required int consultantId,
    required String date,
    required String time,
    int? clientLocationId,
    int? paymentMethodId,
    String? cardToken,
    String? notes,
  }) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 500));
        return BookingCreateResult(
          booking: Booking(
            id: 6,
            reference: 'BK-2026-000006',
            status: 'pending',
            statusLabel: tr('statusPending'),
            paymentStatus: 'paid',
            date: date,
            time: time,
            amountFormatted: mockPackages.first.priceFormatted,
            meetingUrl: 'https://meet.google.com/abc-defg-hij',
          ),
          paymentStatus: 'paid',
        );
      }
      final data = asMap(await _api.post(Endpoints.bookings, {
        'package_id': packageId,
        'consultant_id': consultantId,
        'date': date,
        'time': time,
        if (clientLocationId != null) 'client_location_id': clientLocationId,
        if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
        if (cardToken != null) 'card_token': cardToken,
        if (notes != null && notes.isNotEmpty) 'client_notes': notes,
      }));
      final payment = asMap(data['payment']);
      return BookingCreateResult(
        booking: Booking.fromJson(asMap(data['booking'])),
        paymentStatus: payment['status'] as String?,
        transactionUrl: payment['transaction_url'] as String?,
        paymentId: payment['id'] as int?,
      );
    });
  }

  Future<Result<Booking>> booking(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        final found = mockBookings.where((item) => item.id == id);
        if (found.isEmpty) {
          throw ApiException(tr('loadFailed'), code: 'NOT_FOUND', statusCode: 404);
        }
        final item = found.first;
        return item.copyWith(
          durationMinutes: item.durationMinutes == 0 ? 30 : item.durationMinutes,
          clientNotes: item.clientNotes.isEmpty && item.id == 5
              ? tr('mockBookingNote')
              : item.clientNotes,
          locationLabel: item.locationLabel.isEmpty
              ? '${tr('mockLocName')} — ${tr('mockLocCity')} — ${tr('mockLocAddress')}'
              : item.locationLabel,
          paymentLabel: item.paymentLabel.isNotEmpty
              ? item.paymentLabel
              : (item.paymentStatus == 'paid' ? 'Visa •••• 4242' : item.paymentStatus),
        );
      }
      return Booking.fromJson(asMap(await _api.get(Endpoints.booking(id))));
    });
  }

  Future<Result<List<Booking>>> bookings() {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 150));
        return mockBookings;
      }
      return asList(await _api.get(Endpoints.bookings), Booking.fromJson);
    });
  }

  Future<Result<void>> cancelBooking(int id) {
    return guard(() async {
      if (AppConfig.useMock) {
        await Future.delayed(const Duration(milliseconds: 250));
        return;
      }
      await _api.post(Endpoints.cancelBooking(id));
    });
  }
}
