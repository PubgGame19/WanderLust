import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_service.dart';

// ---------------------------------------------------------------------------
// 1. COMMUNITY TRIPS LIST STATE & NOTIFIER
// ---------------------------------------------------------------------------

class TripsState {
  final bool isLoading;
  final List<TripListItemModel> trips;
  final String? errorMessage;
  final String searchQuery;

  TripsState({
    this.isLoading = false,
    this.trips = const [],
    this.errorMessage,
    this.searchQuery = '',
  });

  TripsState copyWith({
    bool? isLoading,
    List<TripListItemModel>? trips,
    String? errorMessage,
    String? searchQuery,
  }) {
    return TripsState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TripsNotifier extends StateNotifier<TripsState> {
  final ApiService _api;

  TripsNotifier(this._api) : super(TripsState(isLoading: true)) {
    fetchTrips();
  }

  Future<void> fetchTrips({String? search}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, searchQuery: search ?? state.searchQuery);
    try {
      final trips = await _api.getTrips(search: state.searchQuery.isNotEmpty ? state.searchQuery : null);
      state = state.copyWith(isLoading: false, trips: trips);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setSearch(String query) {
    fetchTrips(search: query);
  }
}

final tripsProvider = StateNotifierProvider<TripsNotifier, TripsState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TripsNotifier(api);
});

// ---------------------------------------------------------------------------
// 2. SINGLE TRIP DETAIL FUTURE PROVIDER
// ---------------------------------------------------------------------------

final tripDetailProvider = FutureProvider.family<TripModel, String>((ref, tripId) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getTripDetail(tripId);
});

// ---------------------------------------------------------------------------
// 3. ADD TRIP DRAFT STATE NOTIFIER (WITH PHOTO UPLOADS)
// ---------------------------------------------------------------------------

class AddTripDraftState {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final double? totalExpense;
  final String currency;
  final String? transportMode;
  final int rating;
  final List<TripPlaceDraftModel> places;
  final List<String> tripLocalImagePaths;
  final bool isSubmitting;
  final String? statusMessage;
  final String? errorMessage;

  AddTripDraftState({
    this.title = '',
    DateTime? startDate,
    DateTime? endDate,
    this.description,
    this.totalExpense,
    this.currency = 'INR',
    this.transportMode = 'Car / Road Trip',
    this.rating = 5,
    this.places = const [],
    this.tripLocalImagePaths = const [],
    this.isSubmitting = false,
    this.statusMessage,
    this.errorMessage,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(const Duration(days: 2));

  AddTripDraftState copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    double? totalExpense,
    String? currency,
    String? transportMode,
    int? rating,
    List<TripPlaceDraftModel>? places,
    List<String>? tripLocalImagePaths,
    bool? isSubmitting,
    String? statusMessage,
    String? errorMessage,
  }) {
    return AddTripDraftState(
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      totalExpense: totalExpense ?? this.totalExpense,
      currency: currency ?? this.currency,
      transportMode: transportMode ?? this.transportMode,
      rating: rating ?? this.rating,
      places: places ?? this.places,
      tripLocalImagePaths: tripLocalImagePaths ?? this.tripLocalImagePaths,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage,
    );
  }
}

class AddTripDraftNotifier extends StateNotifier<AddTripDraftState> {
  AddTripDraftNotifier() : super(AddTripDraftState());

  void updateMetadata({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    double? totalExpense,
    String? currency,
    String? transportMode,
    int? rating,
    List<String>? tripLocalImagePaths,
  }) {
    state = state.copyWith(
      title: title ?? state.title,
      startDate: startDate ?? state.startDate,
      endDate: endDate ?? state.endDate,
      description: description ?? state.description,
      totalExpense: totalExpense ?? state.totalExpense,
      currency: currency ?? state.currency,
      transportMode: transportMode ?? state.transportMode,
      rating: rating ?? state.rating,
      tripLocalImagePaths: tripLocalImagePaths ?? state.tripLocalImagePaths,
    );
  }

  void addPlace(TripPlaceDraftModel place) {
    final updatedList = List<TripPlaceDraftModel>.from(state.places);
    place.visitOrder = updatedList.length + 1;
    updatedList.add(place);
    state = state.copyWith(places: updatedList);
  }

  void updatePlace(int index, TripPlaceDraftModel updatedPlace) {
    if (index < 0 || index >= state.places.length) return;
    final updatedList = List<TripPlaceDraftModel>.from(state.places);
    updatedList[index] = updatedPlace;
    state = state.copyWith(places: updatedList);
  }

  void removePlace(int index) {
    if (index < 0 || index >= state.places.length) return;
    final updatedList = List<TripPlaceDraftModel>.from(state.places);
    updatedList.removeAt(index);
    for (int i = 0; i < updatedList.length; i++) {
      updatedList[i].visitOrder = i + 1;
    }
    state = state.copyWith(places: updatedList);
  }

  void reorderPlaces(int oldIndex, int newIndex) {
    final updatedList = List<TripPlaceDraftModel>.from(state.places);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updatedList.removeAt(oldIndex);
    updatedList.insert(newIndex, item);
    for (int i = 0; i < updatedList.length; i++) {
      updatedList[i].visitOrder = i + 1;
    }
    state = state.copyWith(places: updatedList);
  }

  void resetDraft() {
    state = AddTripDraftState();
  }

  Future<TripModel> publishTrip(ApiService api) async {
    state = state.copyWith(isSubmitting: true, statusMessage: "Uploading travel photos...", errorMessage: null);
    try {
      // 1. Upload photos for each visited location experience
      for (int i = 0; i < state.places.length; i++) {
        final place = state.places[i];
        if (place.localImagePaths.isNotEmpty) {
          state = state.copyWith(statusMessage: "Uploading photos for ${place.displayName} (${i + 1}/${state.places.length})...");
          final uploadedUrls = await api.uploadMediaFiles(place.localImagePaths);
          place.photoUrls = [...place.photoUrls, ...uploadedUrls];
        }
      }

      // 2. Upload trip-level photos if any
      List<String> tripPhotoUrls = [];
      if (state.tripLocalImagePaths.isNotEmpty) {
        state = state.copyWith(statusMessage: "Uploading trip highlights...");
        tripPhotoUrls = await api.uploadMediaFiles(state.tripLocalImagePaths);
      }

      // 3. Post complete trip payload
      state = state.copyWith(statusMessage: "Publishing trip journey...");
      final payload = {
        'title': state.title.trim(),
        'start_date': state.startDate.toIso8601String().split('T').first,
        'end_date': state.endDate.toIso8601String().split('T').first,
        'description': state.description?.trim(),
        'total_expense': state.totalExpense,
        'currency': state.currency,
        'transport_mode': state.transportMode,
        'rating': state.rating,
        'photo_urls': tripPhotoUrls,
        'places': state.places.map((p) => p.toJson()).toList(),
      };

      final createdTrip = await api.createTrip(payload);
      state = state.copyWith(isSubmitting: false, statusMessage: null);
      resetDraft();
      return createdTrip;
    } catch (e) {
      final msg = e.toString().replaceAll("Exception: ", "");
      state = state.copyWith(isSubmitting: false, statusMessage: null, errorMessage: msg);
      rethrow;
    }
  }
}

final addTripDraftProvider = StateNotifierProvider<AddTripDraftNotifier, AddTripDraftState>((ref) {
  return AddTripDraftNotifier();
});
