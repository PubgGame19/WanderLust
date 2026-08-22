import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../locations/location_feed_provider.dart';
import '../trip_provider.dart';
import 'trip_detail_screen.dart';

class TripPreviewScreen extends ConsumerStatefulWidget {
  const TripPreviewScreen({super.key});

  @override
  ConsumerState<TripPreviewScreen> createState() => _TripPreviewScreenState();
}

class _TripPreviewScreenState extends ConsumerState<TripPreviewScreen> {
  Future<void> _publishTrip() async {
    try {
      final api = ref.read(apiServiceProvider);
      final createdTrip = await ref.read(addTripDraftProvider.notifier).publishTrip(api);

      // Refresh community feeds
      ref.read(tripsProvider.notifier).fetchTrips();
      ref.read(locationsProvider.notifier).fetchLocations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.positiveGreen,
            content: Text("Trip and photos published successfully! AI extraction underway."),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailScreen(tripId: createdTrip.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.challengeRed,
            content: Text("Failed to publish trip: ${e.toString().replaceAll('Exception: ', '')}"),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draft = ref.watch(addTripDraftProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Preview", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Overview Header Card
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${draft.places.length} DESTINATIONS",
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text("${draft.rating}/5", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    draft.title,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${dateFormat.format(draft.startDate)}  •  ${dateFormat.format(draft.endDate)}",
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (draft.totalExpense != null) ...[
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${draft.currency} ${draft.totalExpense!.toStringAsFixed(0)}",
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (draft.transportMode != null) ...[
                        const Icon(Icons.directions_car_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          draft.transportMode!,
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (draft.description != null && draft.description!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Text(
                  draft.description!,
                  style: GoogleFonts.inter(fontSize: 13.5, height: 1.5),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Visited Destinations & Experiences Breakdown
            Text(
              "Visited Places & Experiences",
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: draft.places.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final place = draft.places[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.sunsetAmber,
                            foregroundColor: Colors.white,
                            child: Text("${index + 1}", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              place.displayName,
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.alertAmber, size: 16),
                              const SizedBox(width: 2),
                              Text("${place.rating}/5", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(place.displaySubtitle, style: GoogleFonts.inter(fontSize: 11.5, color: Colors.grey)),
                      const SizedBox(height: 10),

                      // Raw Experience
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.rawExperience.isNotEmpty ? place.rawExperience : "(No detailed experience provided)",
                              style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                            ),
                            if (place.tips != null && place.tips!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.sunsetAmber, size: 16),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      place.tips!,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sunsetAmber),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Attached Photos Preview
                      if (place.localImagePaths.isNotEmpty) ...[
                        Text(
                          "Attached Photos (${place.localImagePaths.length})",
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: place.localImagePaths.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, photoIdx) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(
                                  File(place.localImagePaths[photoIdx]),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      Row(
                        children: [
                          if (place.expenseAmount != null) ...[
                            Text(
                              "Expense: ${place.currency} ${place.expenseAmount!.toStringAsFixed(0)}",
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.positiveGreen),
                            ),
                            const SizedBox(width: 14),
                          ],
                          if (place.transportMode != null)
                            Text(
                              "Transport: ${place.transportMode}",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Publish Button with upload status message
            if (draft.statusMessage != null) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sunsetAmber)),
                      const SizedBox(width: 10),
                      Text(
                        draft.statusMessage!,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sunsetAmber),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: draft.isSubmitting ? null : _publishTrip,
                child: draft.isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Publish Complete Trip", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
