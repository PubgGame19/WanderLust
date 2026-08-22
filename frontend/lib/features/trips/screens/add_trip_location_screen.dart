import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_service.dart';

class AddTripLocationScreen extends ConsumerStatefulWidget {
  const AddTripLocationScreen({super.key});

  @override
  ConsumerState<AddTripLocationScreen> createState() => _AddTripLocationScreenState();
}

class _AddTripLocationScreenState extends ConsumerState<AddTripLocationScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  bool _showCreateNewForm = false;

  // New location form fields
  final _createFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: "India");
  String _placeType = "monument";

  @override
  void initState() {
    super.initState();
    _performSearch("");
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final results = await api.getLocations(search: query.isNotEmpty ? query : null);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectExistingLocation(LocationModel loc) {
    final draftPlace = TripPlaceDraftModel(
      location: loc,
      rating: 5,
      currency: 'INR',
    );
    Navigator.pop(context, draftPlace);
  }

  void _submitNewLocation() {
    if (!_createFormKey.currentState!.validate()) return;

    final draftPlace = TripPlaceDraftModel(
      newLocationName: _nameCtrl.text.trim(),
      newLocationCity: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      newLocationState: _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
      newLocationCountry: _countryCtrl.text.trim().isNotEmpty ? _countryCtrl.text.trim() : "India",
      newLocationPlaceType: _placeType,
      rating: 5,
      currency: 'INR',
    );
    Navigator.pop(context, draftPlace);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Visited Place", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search input bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => _performSearch(val),
              decoration: InputDecoration(
                hintText: "Search worldwide locations (e.g. Shirdi, Nashik)...",
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.sunsetAmber),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _performSearch("");
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Add New Location Action Card if not found or requested
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetAmber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_location_alt_rounded, color: AppColors.sunsetAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Can't find your destination?",
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "Add a new location node to the global map.",
                          style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showCreateNewForm = !_showCreateNewForm),
                    child: Text(_showCreateNewForm ? "Close" : "+ Add New", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.sunsetAmber)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // New Location Form Expansion
          if (_showCreateNewForm) ...[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _createFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Place Name", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(hintText: "e.g. Trimbakeshwar Shiva Temple"),
                        validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("City / Town", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _cityCtrl,
                                  decoration: const InputDecoration(hintText: "e.g. Nashik"),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("State / Region", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _stateCtrl,
                                  decoration: const InputDecoration(hintText: "e.g. Maharashtra"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text("Place Type", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: _placeType,
                        decoration: const InputDecoration(),
                        items: const [
                          DropdownMenuItem(value: "monument", child: Text("Temple / Monument / Fort")),
                          DropdownMenuItem(value: "mountain", child: Text("Mountain / Trek")),
                          DropdownMenuItem(value: "beach", child: Text("Beach / Coast")),
                          DropdownMenuItem(value: "cafe", child: Text("Cafe / Restaurant")),
                          DropdownMenuItem(value: "place", child: Text("General Attraction")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _placeType = val);
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _submitNewLocation,
                          child: Text("Add Destination to Trip", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Existing Locations List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetAmber))
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            "No matching places found.\nTap '+ Add New' above to create one!",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final loc = _searchResults[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.sunsetAmber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.place_rounded, color: AppColors.sunsetAmber),
                                ),
                                title: Text(loc.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                  "${loc.city ?? loc.stateRegion ?? ''}, ${loc.country} • ${loc.placeType.toUpperCase()}",
                                  style: GoogleFonts.inter(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.add_circle_outline_rounded, color: AppColors.sunsetAmber),
                                onTap: () => _selectExistingLocation(loc),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ],
      ),
    );
  }
}
