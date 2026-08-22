import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/models/models.dart';
import '../../core/utils/auth_guard.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_screen.dart';
import '../locations/location_feed_provider.dart';
import '../locations/location_detail_screen.dart';
import '../trips/screens/trips_feed_screen.dart';
import '../trips/screens/add_trip_screen.dart';
import '../trips/trip_provider.dart';
import '../ai_assistant/ai_assistant_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _categories = [
    {"label": "All Nodes", "type": "all", "icon": "🌍"},
    {"label": "Forts & Treks", "type": "fort", "icon": "🏰"},
    {"label": "Mountains", "type": "mountain", "icon": "⛰️"},
    {"label": "Beaches", "type": "beach", "icon": "🏖️"},
    {"label": "Monuments", "type": "monument", "icon": "🏛️"},
    {"label": "Cafes", "type": "cafe", "icon": "☕"},
  ];

  @override
  void dispose() {
    _searchController.dispose();
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

    final List<Widget> screens = [
      _buildExploreTab(context, isDark),
      const TripsFeedScreen(),
      const AIAssistantScreen(),
      _buildProfileTab(context, isDark),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          border: Border(
            top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          selectedItemColor: AppColors.sunsetAmber,
          unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11.5),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 10.5),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              activeIcon: Icon(Icons.explore_rounded),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flight_takeoff_rounded),
              activeIcon: Icon(Icons.flight_takeoff_rounded),
              label: "Journeys",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_rounded),
              activeIcon: Icon(Icons.auto_awesome_rounded),
              label: "AI Copilot",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab(BuildContext context, bool isDark) {
    final locationsState = ref.watch(locationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.sunsetAmber, AppColors.amberLight],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              "WanderLust",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 0.2, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Add Trip Quick Action
          IconButton(
            tooltip: "Share Your Trip",
            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.sunsetAmber),
            onPressed: _openAddTrip,
          ),
          // Theme Toggle Button
          IconButton(
            tooltip: "Toggle OLED Dark / Light Mode",
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.alertAmber : AppColors.electricViolet,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.sunsetAmber,
        onRefresh: () async {
          await ref.read(locationsProvider.notifier).fetchLocations();
        },
        child: CustomScrollView(
          slivers: [
            // Top Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => ref.read(locationsProvider.notifier).setSearch(val),
                  decoration: InputDecoration(
                    hintText: "Search places, forts, mountains, cities...",
                    prefixIcon: const Icon(Icons.search_rounded, size: 22, color: AppColors.sunsetAmber),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(locationsProvider.notifier).setSearch("");
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // Horizontal Category Selector
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = locationsState.selectedPlaceType == cat['type'];
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text("${cat['icon']} ${cat['label']}"),
                      labelStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      selectedColor: AppColors.sunsetAmber,
                      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                      side: BorderSide(
                        color: isSelected ? AppColors.sunsetAmber : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      onSelected: (_) => ref.read(locationsProvider.notifier).setFilter(cat['type']!),
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Verified Travel Nodes",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      "${locationsState.locations.length} found",
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Locations List / Grid
            if (locationsState.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.sunsetAmber),
                ),
              )
            else if (locationsState.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 60, color: AppColors.challengeRed),
                        const SizedBox(height: 16),
                        Text("Connection Error", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          locationsState.error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(locationsProvider.notifier).fetchLocations(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (locationsState.locations.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.travel_explore_rounded, size: 64, color: AppColors.sunsetAmber),
                      const SizedBox(height: 16),
                      Text("No locations found", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text("Try clearing your search filters.", style: GoogleFonts.inter(fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final location = locationsState.locations[index];
                      return _buildLocationCard(context, location, isDark);
                    },
                    childCount: locationsState.locations.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, LocationModel location, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LocationDetailScreen(initialLocation: location),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Top Badges
            Stack(
              children: [
                if (location.coverImageUrl != null)
                  Image.network(
                    location.coverImageUrl!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 190,
                      color: isDark ? AppColors.darkCardElevated : Colors.grey.shade300,
                      child: const Icon(Icons.landscape_rounded, size: 48),
                    ),
                  )
                else
                  Container(
                    height: 190,
                    color: isDark ? AppColors.darkCardElevated : Colors.grey.shade300,
                    child: const Icon(Icons.landscape_rounded, size: 48),
                  ),

                // Top Place Type Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          location.placeType.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Verified Badge
                if (location.verified)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.positiveGreen.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text("Verified", style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Card Body Details
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          location.name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                      if (location.averageRating != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.alertAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.alertAmber),
                              const SizedBox(width: 4),
                              Text(
                                "${location.averageRating}",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.alertAmber,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${location.city ?? location.stateRegion ?? ''}, ${location.country}",
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (location.description != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      location.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${location.reviewCount} Community Experiences",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sunsetAmber,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "View Feed",
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.sunsetAmber),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(BuildContext context, bool isDark) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isGuest = !authState.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text("Explorer Profile", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.sunsetAmber.withOpacity(0.2),
                  backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                  child: user?.avatarUrl == null
                      ? Icon(
                          isGuest ? Icons.person_outline_rounded : Icons.person_rounded,
                          size: 48,
                          color: AppColors.sunsetAmber,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  isGuest ? "Guest Explorer" : (user?.fullName ?? "@${user?.username}"),
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                Text(
                  isGuest ? "Browse Mode • Unauthenticated" : (user?.email ?? ""),
                  style: GoogleFonts.inter(color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Guest Mode Callout Card
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.sunsetAmber.withOpacity(isDark ? 0.15 : 0.08),
                    AppColors.electricViolet.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_open_rounded, color: AppColors.sunsetAmber, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "Unlock Full Privileges",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in or register to share complete multi-destination journeys, submit verified reviews, and track your travels.",
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      child: Text(
                        "Sign In / Create Account",
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Theme Switch Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppColors.sunsetAmber),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Dynamic Theme Engine", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        Text(isDark ? "OLED Pure Dark Mode" : "Minimalist Light Mode", style: GoogleFonts.inter(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  activeColor: AppColors.sunsetAmber,
                  onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Architectural Invariants Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("WANDERLUST ARCHITECTURE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.sunsetAmber)),
                const SizedBox(height: 8),
                _buildInvariantLine("1. Strict Spatial Normalization", "All content constrained to location_id"),
                _buildInvariantLine("2. Immutable Raw Data", "Raw reviews never overwritten by AI"),
                _buildInvariantLine("3. Multi-Destination Journeys", "Real-world trips containing ordered location experiences"),
                _buildInvariantLine("4. Anti-Hallucination Guardrails", "Strict JSON schema mode with null fallback"),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Button: Sign Out (if authenticated)
          if (!isGuest)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.challengeRed,
                  side: BorderSide(color: AppColors.challengeRed.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text("Sign Out", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInvariantLine(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
