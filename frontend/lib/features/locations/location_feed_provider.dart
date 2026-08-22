import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/network/api_service.dart';

// State for Locations List
class LocationsState {
  final List<LocationModel> locations;
  final bool isLoading;
  final String? error;
  final String selectedPlaceType;
  final String searchQuery;

  LocationsState({
    this.locations = const [],
    this.isLoading = false,
    this.error,
    this.selectedPlaceType = 'all',
    this.searchQuery = '',
  });

  LocationsState copyWith({
    List<LocationModel>? locations,
    bool? isLoading,
    String? error,
    String? selectedPlaceType,
    String? searchQuery,
  }) {
    return LocationsState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPlaceType: selectedPlaceType ?? this.selectedPlaceType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class LocationsNotifier extends StateNotifier<LocationsState> {
  final ApiService _api;

  LocationsNotifier(this._api) : super(LocationsState()) {
    fetchLocations();
  }

  Future<void> fetchLocations({String? search, String? placeType}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: search ?? state.searchQuery,
      selectedPlaceType: placeType ?? state.selectedPlaceType,
    );

    try {
      final locs = await _api.getLocations(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        placeType: state.selectedPlaceType != 'all' ? state.selectedPlaceType : null,
      );
      state = state.copyWith(locations: locs, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String placeType) {
    state = state.copyWith(selectedPlaceType: placeType);
    fetchLocations(placeType: placeType);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    fetchLocations(search: query);
  }
}

final locationsProvider = StateNotifierProvider<LocationsNotifier, LocationsState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return LocationsNotifier(api);
});

// Provider for Location Detail & Feed
final locationFeedProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, locationId) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getLocationFeed(locationId);
});
