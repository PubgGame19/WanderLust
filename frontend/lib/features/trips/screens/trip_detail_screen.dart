import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../locations/location_detail_screen.dart';
import '../../reviews/widgets/review_card.dart';
import '../trip_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  void _openFullScreenPhoto(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
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
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final api = ref.watch(apiServiceProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Story", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: tripAsync.when(
        data: (trip) {
          DateTime? sDate = DateTime.tryParse(trip.startDate);
          DateTime? eDate = DateTime.tryParse(trip.endDate);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Trip Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sunsetAmber, AppColors.amberLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sunsetAmber.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    trip.author.username.isNotEmpty ? trip.author.username[0].toUpperCase() : 'T',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppColors.sunsetAmber),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    "@${trip.author.username}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trip.rating != null) ...[
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                                Text("${trip.rating}/5", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        trip.title,
                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      if (sDate != null && eDate != null)
                        Text(
                          "${dateFormat.format(sDate)}  —  ${dateFormat.format(eDate)}",
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                        ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          if (trip.totalExpense != null) ...[
                            const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "${trip.currency} ${trip.totalExpense!.toStringAsFixed(0)}",
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            const SizedBox(width: 16),
                          ],
                          if (trip.transportMode != null) ...[
                            const Icon(Icons.directions_car_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              trip.transportMode!,
                              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (trip.description != null && trip.description!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Route Summary & Takeaways", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(
                          trip.description!,
                          style: GoogleFonts.inter(fontSize: 13.5, height: 1.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Visited Locations Section
                Text(
                  "Journey Timeline (${trip.places.length} stops)",
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trip.places.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final place = trip.places[index];
                    final rawPhotos = place.experience?.rawLayer.photos ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Place Header Badge
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationDetailScreen(initialLocation: place.location),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.sunsetAmber,
                                  foregroundColor: Colors.white,
                                  child: Text("${place.visitOrder}", style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.location.name,
                                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        "${place.location.city ?? place.location.stateRegion ?? ''}, ${place.location.country}",
                                        style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.sunsetAmber),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Place Photo Gallery Strip if photos exist
                        if (rawPhotos.isNotEmpty) ...[
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: rawPhotos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, pIdx) {
                                final photoUrl = api.resolveImageUrl(rawPhotos[pIdx]);
                                return InkWell(
                                  onTap: () => _openFullScreenPhoto(context, photoUrl),
                                  borderRadius: BorderRadius.circular(12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      photoUrl,
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 110,
                                        height: 110,
                                        color: isDark ? AppColors.darkCard : Colors.grey.shade300,
                                        child: const Icon(Icons.broken_image_rounded),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Place Experience Card
                        if (place.experience != null)
                          ReviewCard(reviewItem: place.experience!)
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 12.0),
                            child: Text(
                              "Visited without a detailed review.",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.sunsetAmber)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.challengeRed, size: 48),
              const SizedBox(height: 12),
              Text("Failed to load trip story", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(err.toString(), style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
