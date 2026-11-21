import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../models/page_response.dart';
import '../models/vehicle.dart';
import '../network/dio_client.dart';
import '../network/vehicle_api.dart';
import '../repositories/vehicle_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  // ref.read (not watch) inside the callbacks: the client lives for the whole app and reads the
  // token fresh on every request.
  final dio = createDioClient(
    readToken: () => ref.read(authProvider).token,
    onUnauthorized: () => ref.read(authProvider.notifier).sessionEnded(),
  );
  ref.onDispose(dio.close);
  return dio;
});

final vehicleApiProvider = Provider<VehicleApi>((ref) {
  return VehicleApi(ref.watch(dioProvider));
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository(ref.watch(vehicleApiProvider));
});

/// What the register is showing: all of it lives in the URL (`/vehicles?page=2&q=..&status=..`).
typedef VehicleQuery = ({int page, String? q, VehicleStatus? status});

// Errors show at once with a "Try again" button, rather than Riverpod 3's silent automatic retry.
Duration? _noRetry(int _, Object _) => null;

/// One page of the register. Changing page, search or filter is a new key, so it loads fresh
/// (skeleton rows) and the counts below it come from the same response.
final vehiclePageProvider = FutureProvider.autoDispose.family<PageResponse<Vehicle>, VehicleQuery>(
  (ref, query) => ref.watch(vehicleRepositoryProvider).getVehicles(page: query.page, q: query.q, status: query.status),
  retry: _noRetry,
);

/// Vehicles per status for the search text, for the filter chips.
final statusCountsProvider = FutureProvider.autoDispose.family<Map<VehicleStatus, int>, String?>(
  (ref, q) => ref.watch(vehicleRepositoryProvider).getStatusCounts(q: q),
  retry: _noRetry,
);

/// One vehicle, for the detail panel and the edit form.
final vehicleProvider = FutureProvider.autoDispose.family<Vehicle, int>(
  (ref, id) => ref.watch(vehicleRepositoryProvider).getVehicleById(id),
  retry: _noRetry,
);

/// Reload everything that shows vehicles, after a register, edit or remove.
void refreshVehicles(WidgetRef ref) {
  ref.invalidate(vehiclePageProvider);
  ref.invalidate(statusCountsProvider);
  ref.invalidate(vehicleProvider);
}

/// A row to mark after the list reloads: [fresh] flashes (just saved), [leaving] slides away (just removed).
class RowMarkNotifier extends Notifier<({int? fresh, int? leaving})> {
  @override
  ({int? fresh, int? leaving}) build() => (fresh: null, leaving: null);

  void fresh(int id) => state = (fresh: id, leaving: null);
  void leaving(int id) => state = (fresh: null, leaving: id);
  void clear() => state = (fresh: null, leaving: null);
}

final rowMarkProvider = NotifierProvider<RowMarkNotifier, ({int? fresh, int? leaving})>(RowMarkNotifier.new);

class VehicleFormState {
  const VehicleFormState({
    this.isSubmitting = false,
    this.vehicleNumberError,
    this.generalError,
    this.fieldErrors = const {},
    this.isConflict = false,
  });

  final bool isSubmitting;

  /// The plate is already registered (409): the form links to that vehicle.
  final bool isConflict;
  final String? vehicleNumberError;
  final String? generalError;
  final Map<String, String> fieldErrors;

  VehicleFormState copyWith({
    bool? isSubmitting,
    String? vehicleNumberError,
    bool clearVehicleNumberError = false,
    String? generalError,
    bool clearGeneralError = false,
    Map<String, String>? fieldErrors,
  }) {
    return VehicleFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      vehicleNumberError: clearVehicleNumberError
          ? null
          : (vehicleNumberError ?? this.vehicleNumberError),
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class VehicleFormNotifier extends Notifier<VehicleFormState> {
  @override
  VehicleFormState build() => const VehicleFormState();

  void clearVehicleNumberError() {
    if (state.vehicleNumberError != null) {
      state = state.copyWith(clearVehicleNumberError: true);
    }
  }

  void clearErrors() {
    state = const VehicleFormState();
  }

  Future<Vehicle?> submit({
    int? existingId,
    required Vehicle vehicle,
  }) async {
    state = const VehicleFormState(isSubmitting: true);

    final repo = ref.read(vehicleRepositoryProvider);
    try {
      final result = existingId == null
          ? await repo.createVehicle(vehicle)
          : await repo.updateVehicle(existingId, vehicle);
      state = const VehicleFormState(isSubmitting: false);
      return result;
    } on VehicleApiException catch (e) {
      final fieldErrors = e.fieldErrors ?? const {};
      if (e.isConflict) {
        state = VehicleFormState(
          isSubmitting: false,
          vehicleNumberError: e.message,
          fieldErrors: fieldErrors,
          isConflict: true,
        );
      } else if (fieldErrors.containsKey('vehicleNumber')) {
        state = VehicleFormState(
          isSubmitting: false,
          vehicleNumberError: fieldErrors['vehicleNumber'],
          generalError: e.message,
          fieldErrors: fieldErrors,
        );
      } else {
        state = VehicleFormState(
          isSubmitting: false,
          generalError: e.message,
          fieldErrors: fieldErrors,
        );
      }
      return null;
    } catch (_) {
      state = const VehicleFormState(
        isSubmitting: false,
        generalError: 'An unexpected error occurred while saving the vehicle.',
      );
      return null;
    }
  }
}

final vehicleFormProvider =
    NotifierProvider.autoDispose<VehicleFormNotifier, VehicleFormState>(
  VehicleFormNotifier.new,
);
