class UserModel {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
    );
  }
}

class UserAuthorModel {
  final String id;
  final String username;
  final String? avatarUrl;

  UserAuthorModel({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory UserAuthorModel.fromJson(Map<String, dynamic> json) {
    return UserAuthorModel(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Traveler',
      avatarUrl: json['avatar_url'],
    );
  }
}

class LocationModel {
  final String id;
  final String name;
  final String slug;
  final String continent;
  final String country;
  final String? stateRegion;
  final String? city;
  final String placeType;
  final double latitude;
  final double longitude;
  final String? coverImageUrl;
  final String? description;
  final bool verified;
  final double? distanceKm;
  final double? averageRating;
  final int reviewCount;

  LocationModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.continent,
    required this.country,
    this.stateRegion,
    this.city,
    required this.placeType,
    required this.latitude,
    required this.longitude,
    this.coverImageUrl,
    this.description,
    this.verified = true,
    this.distanceKm,
    this.averageRating,
    this.reviewCount = 0,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      continent: json['continent'] ?? '',
      country: json['country'] ?? '',
      stateRegion: json['state_region'],
      city: json['city'],
      placeType: json['place_type'] ?? 'place',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      coverImageUrl: json['cover_image_url'],
      description: json['description'],
      verified: json['verified'] ?? true,
      distanceKm: (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : null,
      averageRating: (json['average_rating'] is num) ? (json['average_rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] ?? 0,
    );
  }
}

class LocationAIInsightsModel {
  final String locationId;
  final List<String> aggregatedPositives;
  final List<String> aggregatedChallenges;
  final double? expenseRangeMin;
  final double? expenseRangeMax;
  final String dominantCurrency;
  final List<String> bestVisitTimes;
  final int sampleSize;

  LocationAIInsightsModel({
    required this.locationId,
    required this.aggregatedPositives,
    required this.aggregatedChallenges,
    this.expenseRangeMin,
    this.expenseRangeMax,
    this.dominantCurrency = 'USD',
    required this.bestVisitTimes,
    this.sampleSize = 0,
  });

  factory LocationAIInsightsModel.fromJson(Map<String, dynamic> json) {
    return LocationAIInsightsModel(
      locationId: json['location_id'] ?? '',
      aggregatedPositives: (json['aggregated_positives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      aggregatedChallenges: (json['aggregated_challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      expenseRangeMin: (json['expense_range_min'] is num) ? (json['expense_range_min'] as num).toDouble() : null,
      expenseRangeMax: (json['expense_range_max'] is num) ? (json['expense_range_max'] as num).toDouble() : null,
      dominantCurrency: json['dominant_currency'] ?? 'USD',
      bestVisitTimes: (json['best_visit_times'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sampleSize: json['sample_size'] ?? 0,
    );
  }
}

class ReviewAILayerModel {
  final String summary;
  final List<String> highlights;
  final List<String> challenges;
  final List<String> extractedTips;
  final String sentiment;
  final double? extractedBudgetPerPerson;
  final String processingStatus;

  ReviewAILayerModel({
    required this.summary,
    required this.highlights,
    required this.challenges,
    required this.extractedTips,
    required this.sentiment,
    this.extractedBudgetPerPerson,
    required this.processingStatus,
  });

  factory ReviewAILayerModel.fromJson(Map<String, dynamic> json) {
    return ReviewAILayerModel(
      summary: json['summary'] ?? 'AI extraction pending...',
      highlights: (json['highlights'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      challenges: (json['challenges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      extractedTips: (json['extracted_tips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      sentiment: json['sentiment'] ?? 'neutral',
      extractedBudgetPerPerson: (json['extracted_budget_per_person'] is num)
          ? (json['extracted_budget_per_person'] as num).toDouble()
          : null,
      processingStatus: json['processing_status'] ?? 'pending',
    );
  }
}

class ReviewRawLayerModel {
  final String originalText;
  final double? expenseAmount;
  final String currency;
  final int? groupSize;
  final String? transportMode;
  final String? startingLocation;
  final String visitDate;
  final List<String> photos;

  ReviewRawLayerModel({
    required this.originalText,
    this.expenseAmount,
    this.currency = 'USD',
    this.groupSize,
    this.transportMode,
    this.startingLocation,
    required this.visitDate,
    required this.photos,
  });

  factory ReviewRawLayerModel.fromJson(Map<String, dynamic> json) {
    return ReviewRawLayerModel(
      originalText: json['original_text'] ?? '',
      expenseAmount: (json['expense_amount'] is num) ? (json['expense_amount'] as num).toDouble() : null,
      currency: json['currency'] ?? 'USD',
      groupSize: json['group_size'],
      transportMode: json['transport_mode'],
      startingLocation: json['starting_location'],
      visitDate: json['visit_date'] ?? '',
      photos: (json['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ReviewFeedItemModel {
  final String reviewId;
  final String? locationId;
  final String? locationName;
  final String? tripId;
  final String? tripTitle;
  final UserAuthorModel author;
  final int rating;
  final DateTime createdAt;
  final ReviewAILayerModel aiLayer;
  final ReviewRawLayerModel rawLayer;

  ReviewFeedItemModel({
    required this.reviewId,
    this.locationId,
    this.locationName,
    this.tripId,
    this.tripTitle,
    required this.author,
    required this.rating,
    required this.createdAt,
    required this.aiLayer,
    required this.rawLayer,
  });

  factory ReviewFeedItemModel.fromJson(Map<String, dynamic> json) {
    return ReviewFeedItemModel(
      reviewId: json['review_id'] ?? '',
      locationId: json['location_id'],
      locationName: json['location_name'],
      tripId: json['trip_id'],
      tripTitle: json['trip_title'],
      author: UserAuthorModel.fromJson(json['author'] ?? {}),
      rating: json['rating'] ?? 5,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      aiLayer: ReviewAILayerModel.fromJson(json['ai_layer'] ?? {}),
      rawLayer: ReviewRawLayerModel.fromJson(json['raw_layer'] ?? {}),
    );
  }
}

// ---------------------------------------------------------------------------
// TRIP & MEDIA DATA MODELS
// ---------------------------------------------------------------------------

class PhotoModel {
  final String id;
  final String userId;
  final String? tripId;
  final String? tripTitle;
  final String? reviewId;
  final String locationId;
  final String? locationName;
  final String imageUrl;
  final String? thumbnailUrl;
  final int displayOrder;
  final UserAuthorModel author;
  final DateTime createdAt;

  PhotoModel({
    required this.id,
    required this.userId,
    this.tripId,
    this.tripTitle,
    this.reviewId,
    required this.locationId,
    this.locationName,
    required this.imageUrl,
    this.thumbnailUrl,
    this.displayOrder = 0,
    required this.author,
    required this.createdAt,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      tripId: json['trip_id'],
      tripTitle: json['trip_title'],
      reviewId: json['review_id'],
      locationId: json['location_id'] ?? '',
      locationName: json['location_name'],
      imageUrl: json['image_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      displayOrder: json['display_order'] ?? 0,
      author: UserAuthorModel.fromJson(json['author'] ?? {}),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class TripPlaceDraftModel {
  LocationModel? location;
  String? newLocationName;
  String? newLocationCity;
  String? newLocationState;
  String? newLocationCountry;
  String? newLocationPlaceType;
  double? newLocationLat;
  double? newLocationLng;
  String? newLocationDescription;

  // Location Experience details
  int rating;
  String rawExperience;
  double? expenseAmount;
  String currency;
  String? transportMode;
  String? tips;
  int visitOrder;
  List<String> localImagePaths;
  List<String> photoUrls;

  TripPlaceDraftModel({
    this.location,
    this.newLocationName,
    this.newLocationCity,
    this.newLocationState,
    this.newLocationCountry = 'India',
    this.newLocationPlaceType = 'place',
    this.newLocationLat,
    this.newLocationLng,
    this.newLocationDescription,
    this.rating = 5,
    this.rawExperience = '',
    this.expenseAmount,
    this.currency = 'INR',
    this.transportMode,
    this.tips,
    this.visitOrder = 1,
    List<String>? localImagePaths,
    List<String>? photoUrls,
  })  : localImagePaths = localImagePaths ?? [],
        photoUrls = photoUrls ?? [];

  String get displayName => location?.name ?? newLocationName ?? 'Visited Place';
  String get displaySubtitle => location != null
      ? "${location!.city ?? location!.stateRegion ?? ''}, ${location!.country}"
      : "${newLocationCity ?? newLocationState ?? ''}, ${newLocationCountry ?? ''}";

  Map<String, dynamic> toJson() {
    return {
      if (location != null) 'location_id': location!.id,
      if (location == null && newLocationName != null && newLocationName!.trim().isNotEmpty) ...{
        'new_location_name': newLocationName!.trim(),
        'city': newLocationCity?.trim(),
        'state_region': newLocationState?.trim(),
        'country': newLocationCountry?.trim() ?? 'India',
        'place_type': newLocationPlaceType?.trim() ?? 'place',
        'latitude': newLocationLat,
        'longitude': newLocationLng,
        'description': newLocationDescription?.trim(),
      },
      'rating': rating,
      'raw_text': rawExperience.trim().isNotEmpty ? rawExperience.trim() : null,
      'expense_amount': expenseAmount,
      'currency': currency,
      'transport_mode': transportMode,
      'tips': tips?.trim().isNotEmpty == true ? tips!.trim() : null,
      'visit_order': visitOrder,
      'photo_urls': photoUrls,
    };
  }
}

class TripPlaceModel {
  final LocationModel location;
  final int visitOrder;
  final ReviewFeedItemModel? experience;

  TripPlaceModel({
    required this.location,
    required this.visitOrder,
    this.experience,
  });

  factory TripPlaceModel.fromJson(Map<String, dynamic> json) {
    return TripPlaceModel(
      location: LocationModel.fromJson(json['location'] ?? {}),
      visitOrder: json['visit_order'] ?? 1,
      experience: json['experience'] != null ? ReviewFeedItemModel.fromJson(json['experience']) : null,
    );
  }
}

class TripModel {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final String? description;
  final double? totalExpense;
  final String currency;
  final String? transportMode;
  final int? rating;
  final UserAuthorModel author;
  final List<TripPlaceModel> places;
  final int placesCount;
  final DateTime createdAt;

  TripModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.totalExpense,
    this.currency = 'INR',
    this.transportMode,
    this.rating,
    required this.author,
    required this.places,
    required this.placesCount,
    required this.createdAt,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'],
      totalExpense: (json['total_expense'] is num) ? (json['total_expense'] as num).toDouble() : null,
      currency: json['currency'] ?? 'INR',
      transportMode: json['transport_mode'],
      rating: json['rating'],
      author: UserAuthorModel.fromJson(json['author'] ?? {}),
      places: (json['places'] as List<dynamic>?)?.map((e) => TripPlaceModel.fromJson(e)).toList() ?? [],
      placesCount: json['places_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class TripListItemModel {
  final String id;
  final String title;
  final String startDate;
  final String endDate;
  final String? description;
  final double? totalExpense;
  final String currency;
  final String? transportMode;
  final int? rating;
  final UserAuthorModel author;
  final int placesCount;
  final List<String> visitedPlaceNames;
  final DateTime createdAt;

  TripListItemModel({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.description,
    this.totalExpense,
    this.currency = 'INR',
    this.transportMode,
    this.rating,
    required this.author,
    required this.placesCount,
    required this.visitedPlaceNames,
    required this.createdAt,
  });

  factory TripListItemModel.fromJson(Map<String, dynamic> json) {
    return TripListItemModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'],
      totalExpense: (json['total_expense'] is num) ? (json['total_expense'] as num).toDouble() : null,
      currency: json['currency'] ?? 'INR',
      transportMode: json['transport_mode'],
      rating: json['rating'],
      author: UserAuthorModel.fromJson(json['author'] ?? {}),
      placesCount: json['places_count'] ?? 0,
      visitedPlaceNames: (json['visited_place_names'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}

class AIAssistantCitationModel {
  final String locationName;
  final String locationId;
  final String reviewId;
  final String authorUsername;
  final String quoteSnippet;
  final int rating;

  AIAssistantCitationModel({
    required this.locationName,
    required this.locationId,
    required this.reviewId,
    required this.authorUsername,
    required this.quoteSnippet,
    required this.rating,
  });

  factory AIAssistantCitationModel.fromJson(Map<String, dynamic> json) {
    return AIAssistantCitationModel(
      locationName: json['location_name'] ?? '',
      locationId: json['location_id'] ?? '',
      reviewId: json['review_id'] ?? '',
      authorUsername: json['author_username'] ?? 'Verified Traveler',
      quoteSnippet: json['quote_snippet'] ?? '',
      rating: json['rating'] ?? 5,
    );
  }
}

class AIAssistantResponseModel {
  final String query;
  final String answer;
  final List<LocationModel> recommendedLocations;
  final List<AIAssistantCitationModel> citations;
  final String generatedAt;

  AIAssistantResponseModel({
    required this.query,
    required this.answer,
    required this.recommendedLocations,
    required this.citations,
    required this.generatedAt,
  });

  factory AIAssistantResponseModel.fromJson(Map<String, dynamic> json) {
    return AIAssistantResponseModel(
      query: json['query'] ?? '',
      answer: json['answer'] ?? '',
      recommendedLocations: (json['recommended_locations'] as List<dynamic>?)
              ?.map((e) => LocationModel.fromJson(e))
              .toList() ??
          [],
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => AIAssistantCitationModel.fromJson(e))
              .toList() ??
          [],
      generatedAt: json['generated_at'] ?? '',
    );
  }
}
