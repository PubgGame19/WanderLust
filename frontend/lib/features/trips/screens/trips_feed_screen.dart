import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auth_guard.dart';
import '../trip_provider.dart';
import 'add_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsFeedScreen extends ConsumerStatefulWidget {
  const TripsFeedScreen({super.key});

  @override
  ConsumerState<TripsFeedScreen> createState() => _TripsFeedScreenState();
}

class _TripsFeedScreenState extends ConsumerState<TripsFeedScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddTrip() {
    AuthGuard.requireAuth(
      context: context,
      ref: ref,
      actionTitle: "Share Real-World Trip",
      actionDescription: "Sign up or log in to share your complete trip journey with visited places and insider experiences.",
      onAuthenticated: () async {
        ref.read(addTripDraftProvider.notifier).resetDraft();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddTripScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tripsState = ref.watch(tripsProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text("Real-World Journeys", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        actions: [
          IconButton(
            tooltip: "Add Trip",
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.sunsetAmber),
            onPressed: _openAddTrip,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.sunsetAmber,
        onRefresh: () async {
          await ref.read(tripsProvider.notifier).fetchTrips();
        },
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => ref.read(tripsProvider.notifier).setSearch(val),
                decoration: InputDecoration(
                  hintText: "Search trips by title or visited places...",
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sunsetAmber),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(tripsProvider.notifier).setSearch("");
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Trips List
            Expanded(
              child: tripsState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetAmber))
                  : tripsState.trips.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.flight_takeoff_rounded, size: 54, color: AppColors.sunsetAmber),
                              const SizedBox(height: 14),
                              Text("No trips found", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                "Be the first to share your complete travel story!",
                                style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openAddTrip,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text("Share Your Trip"),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: tripsState.trips.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final trip = tripsState.trips[index];
                            DateTime? sDate = DateTime.tryParse(trip.startDate);
                            DateTime? eDate = DateTime.tryParse(trip.endDate);

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TripDetailScreen(tripId: trip.id),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Author & Rating
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 12,
                                                backgroundColor: AppColors.sunsetAmber.withOpacity(0.2),
                                                child: Text(
                                                  trip.author.username.isNotEmpty ? trip.author.username[0].toUpperCase() : 'T',
                                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.sunsetAmber),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "@${trip.author.username}",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (trip.rating != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.alertAmber.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.star_rounded, size: 14, color: AppColors.alertAmber),
                                                const SizedBox(width: 3),
                                                Text(
                                                  "${trip.rating}",
                                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.alertAmber),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      trip.title,
                                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 4),

                                    if (sDate != null && eDate != null)
                                      Text(
                                        "${dateFormat.format(sDate)}  •  ${dateFormat.format(eDate)}",
                                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                      ),
                                    const SizedBox(height: 10),

                                    // Description snippet
                                    if (trip.description != null && trip.description!.isNotEmpty) ...[
                                      Text(
                                        trip.description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    // Visited Places Chips
                                    if (trip.visitedPlaceNames.isNotEmpty) ...[
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: trip.visitedPlaceNames.map((pName) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.sunsetAmber.withOpacity(isDark ? 0.15 : 0.08),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.place_rounded, size: 12, color: AppColors.sunsetAmber),
                                                const SizedBox(width: 4),
                                                Text(
                                                  pName,
                                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sunsetAmber),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Budget & Transport footer
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            if (trip.totalExpense != null) ...[
                                              Text(
                                                "${trip.currency} ${trip.totalExpense!.toStringAsFixed(0)}",
                                                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.positiveGreen),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                            if (trip.transportMode != null)
                                              Text(
                                                "• ${trip.transportMode}",
                                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                              ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("${trip.placesCount} stops", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                                            const SizedBox(width: 4),
                                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.sunsetAmber),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.sunsetAmber,
        foregroundColor: Colors.white,
        onPressed: _openAddTrip,
        icon: const Icon(Icons.flight_takeoff_rounded),
        label: Text("Share Trip", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
