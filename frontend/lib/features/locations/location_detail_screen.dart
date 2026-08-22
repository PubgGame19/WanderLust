import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/auth_guard.dart';
import '../../core/network/api_service.dart';
import '../reviews/widgets/review_card.dart';
import '../reviews/screens/create_review_screen.dart';
import 'location_feed_provider.dart';

class LocationDetailScreen extends ConsumerWidget {
  final LocationModel initialLocation;

  const LocationDetailScreen({super.key, required this.initialLocation});

  void _openFullScreenPhoto(BuildContext context, String imageUrl, String author, String? tripTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Photo by @$author", style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (tripTitle != null && tripTitle.isNotEmpty)
                  Text("Part of Trip: $tripTitle", style: const TextStyle(color: AppColors.sunsetAmber, fontSize: 11)),
              ],
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedAsync = ref.watch(locationFeedProvider(initialLocation.id));
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      body: feedAsync.when(
        data: (data) {
          final LocationModel location = data['location'] ?? initialLocation;
          final LocationAIInsightsModel? insights = data['insights'];
          final List<ReviewFeedItemModel> reviews = data['reviews'] ?? [];

          // Collect all community photos from all reviews and trips
          final allPhotos = <Map<String, String>>[];
          for (final r in reviews) {
            for (final p in r.rawLayer.photos) {
              allPhotos.add({
                'url': p,
                'author': r.author.username,
                'tripTitle': r.tripTitle ?? '',
              });
            }
          }

          return CustomScrollView(
            slivers: [
              // Hero Parallax AppBar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                stretch: true,
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.bookmark_border_rounded, color: Colors.white),
                    tooltip: "Save Destination",
                    onPressed: () {
                      AuthGuard.requireAuth(
                        context: context,
                        ref: ref,
                        actionTitle: "Save Destination to Favorites",
                        actionDescription: "Log in or create an account to bookmark destinations to your personal explorer collection.",
                        onAuthenticated: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.positiveGreen,
                              content: Text("Destination saved to your favorites!"),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (location.coverImageUrl != null)
                        Image.network(
                          location.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark ? AppColors.darkCardElevated : Colors.grey.shade300,
                            child: const Icon(Icons.landscape_rounded, size: 64),
                          ),
                        )
                      else
                        Container(
                          color: isDark ? AppColors.darkCardElevated : Colors.grey.shade300,
                          child: const Icon(Icons.landscape_rounded, size: 64),
                        ),

                      // Gradient Scrim
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),

                      // Bottom Info in Hero
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.sunsetAmber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    location.placeType.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (location.verified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.positiveGreen,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text(
                                          "Verified Node",
                                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              location.name,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "${location.city ?? location.stateRegion ?? ''}, ${location.country}",
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Strip
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              icon: Icons.star_rounded,
                              iconColor: AppColors.alertAmber,
                              label: "Average",
                              value: location.averageRating != null ? "${location.averageRating} / 5" : "New",
                              isDark: isDark,
                            ),
                            Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            _buildStatItem(
                              icon: Icons.rate_review_rounded,
                              iconColor: AppColors.sunsetAmber,
                              label: "Experiences",
                              value: "${reviews.length}",
                              isDark: isDark,
                            ),
                            Container(width: 1, height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            _buildStatItem(
                              icon: Icons.place_rounded,
                              iconColor: AppColors.electricViolet,
                              label: "Region",
                              value: location.stateRegion ?? location.country,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      if (location.description != null && location.description!.isNotEmpty) ...[
                        Text(
                          "About Destination",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          location.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // COMMUNITY AI AGGREGATED INSIGHTS CARD
                      if (insights != null) ...[
                        _buildAggregatedInsightsCard(context, insights, isDark),
                        const SizedBox(height: 24),
                      ],

                      // COMMUNITY PHOTOS GALLERY SECTION
                      if (allPhotos.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Community Photos",
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              "${allPhotos.length} photos",
                              style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 130,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: allPhotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final item = allPhotos[idx];
                              final photoUrl = api.resolveImageUrl(item['url']);
                              return InkWell(
                                onTap: () => _openFullScreenPhoto(context, photoUrl, item['author']!, item['tripTitle']),
                                borderRadius: BorderRadius.circular(14),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        photoUrl,
                                        width: 130,
                                        height: 130,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 130,
                                          height: 130,
                                          color: isDark ? AppColors.darkCard : Colors.grey.shade300,
                                          child: const Icon(Icons.broken_image_rounded),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 6,
                                      left: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "@${item['author']}",
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Community Reviews Feed Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Verified Community Feed",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${reviews.length} total",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // List of 2-Layer Review Cards
                      if (reviews.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Icon(Icons.rate_review_outlined, size: 48, color: AppColors.sunsetAmber),
                                const SizedBox(height: 12),
                                Text(
                                  "No community reviews yet",
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Be the first to share your authentic travel experience!",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reviews.length,
                          itemBuilder: (context, index) {
                            return ReviewCard(reviewItem: reviews[index]);
                          },
                        ),
                      const SizedBox(height: 80), // Extra space for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetAmber)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.challengeRed, size: 48),
                const SizedBox(height: 12),
                Text("Failed to load destination feed", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(err.toString(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(locationFeedProvider(initialLocation.id)),
                  child: const Text("Retry"),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sunsetAmber,
        foregroundColor: Colors.white,
        onPressed: () {
          AuthGuard.requireAuth(
            context: context,
            ref: ref,
            actionTitle: "Post Verified Travel Review",
            actionDescription: "Authentication is required to submit verified reviews, upload photos, and update community insights.",
            onAuthenticated: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateReviewScreen(location: initialLocation),
                ),
              );
              if (result == true) {
                ref.refresh(locationFeedProvider(initialLocation.id));
              }
            },
          );
        },
        icon: const Icon(Icons.edit_note_rounded),
        label: Text(
          "Write Experience",
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildAggregatedInsightsCard(
    BuildContext context,
    LocationAIInsightsModel insights,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppColors.darkCardElevated, AppColors.darkCard]
              : [Colors.white, AppColors.lightCardElevated],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.electricViolet.withOpacity(0.3) : AppColors.sunsetAmber.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.electricViolet.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.electricViolet.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.insights_rounded, size: 18, color: AppColors.electricViolet),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Community AI Insights",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "N=${insights.sampleSize} REVIEWS",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.electricViolet,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Aggregated Positives
          if (insights.aggregatedPositives.isNotEmpty) ...[
            Text(
              "Top Community Highlights",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.positiveGreen,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: insights.aggregatedPositives.map((pos) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.positiveGreenBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.positiveGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thumb_up_rounded, size: 12, color: AppColors.positiveGreen),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          pos,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.positiveGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Aggregated Challenges
          if (insights.aggregatedChallenges.isNotEmpty) ...[
            Text(
              "Common Challenges & Friction",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.alertAmber,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: insights.aggregatedChallenges.map((chal) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.alertAmberBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.alertAmber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.alertAmber),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          chal,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.alertAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Budget & Best Time Grid
          Row(
            children: [
              if (insights.expenseRangeMin != null && insights.expenseRangeMax != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Est. Budget Range", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          "${insights.dominantCurrency} ${insights.expenseRangeMin!.toStringAsFixed(0)} - ${insights.expenseRangeMax!.toStringAsFixed(0)}",
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              if (insights.expenseRangeMin != null && insights.expenseRangeMax != null) const SizedBox(width: 10),
              if (insights.bestVisitTimes.isNotEmpty)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Best Season", style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          insights.bestVisitTimes.join(", "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
