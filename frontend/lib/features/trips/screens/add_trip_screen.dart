import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../trip_provider.dart';
import 'add_trip_location_screen.dart';
import 'add_location_experience_screen.dart';
import 'trip_preview_screen.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  const AddTripScreen({super.key});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 3));
  DateTime _endDate = DateTime.now();
  String _currency = "INR";
  String _transportMode = "Car / Road Trip";
  int _tripRating = 5;

  final List<String> _transportOptions = [
    "Car / Road Trip",
    "Motorcycle Touring",
    "Train Journey",
    "Flight + Rental",
    "Bus / Backpacking",
    "Mixed Transport",
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _expenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.sunsetAmber,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _addPlace() async {
    final draftPlace = await Navigator.push<TripPlaceDraftModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddTripLocationScreen()),
    );

    if (draftPlace != null && mounted) {
      final configuredPlace = await Navigator.push<TripPlaceDraftModel>(
        context,
        MaterialPageRoute(
          builder: (_) => AddLocationExperienceScreen(draftPlace: draftPlace),
        ),
      );

      if (configuredPlace != null && mounted) {
        ref.read(addTripDraftProvider.notifier).addPlace(configuredPlace);
      }
    }
  }

  Future<void> _editPlace(int index, TripPlaceDraftModel place) async {
    final updated = await Navigator.push<TripPlaceDraftModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLocationExperienceScreen(draftPlace: place),
      ),
    );

    if (updated != null && mounted) {
      ref.read(addTripDraftProvider.notifier).updatePlace(index, updated);
    }
  }

  void _proceedToPreview() {
    if (!_formKey.currentState!.validate()) return;

    final draft = ref.read(addTripDraftProvider);
    if (draft.places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.challengeRed,
          content: Text("Please add at least one visited place to your trip!"),
        ),
      );
      return;
    }

    ref.read(addTripDraftProvider.notifier).updateMetadata(
          title: _titleCtrl.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          description: _descriptionCtrl.text.trim().isNotEmpty ? _descriptionCtrl.text.trim() : null,
          totalExpense: double.tryParse(_expenseCtrl.text.trim()),
          currency: _currency,
          transportMode: _transportMode,
          rating: _tripRating,
        );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TripPreviewScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final draftState = ref.watch(addTripDraftProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text("Share Real-World Trip", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _proceedToPreview,
            child: Text("Preview →", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sunsetAmber)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Overall Trip Details
              Text("1. Trip Overview", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),

              // Title
              Text("Trip Title", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: "e.g. Maharashtra Temple Tour / Monsoon Western Ghats",
                  prefixIcon: Icon(Icons.flight_takeoff_rounded, size: 20, color: AppColors.sunsetAmber),
                ),
                validator: (v) => (v == null || v.trim().length < 3) ? "Trip title is required" : null,
              ),
              const SizedBox(height: 16),

              // Date Range Picker Card
              Text("Trip Dates", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range_rounded, color: AppColors.sunsetAmber, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${dateFormat.format(_startDate)}  —  ${dateFormat.format(_endDate)}",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13.5),
                        ),
                      ),
                      const Icon(Icons.edit_calendar_rounded, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total Expense & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Trip Expense", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _expenseCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "e.g. 5000",
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Currency", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          items: const [
                            DropdownMenuItem(value: "INR", child: Text("INR ₹")),
                            DropdownMenuItem(value: "USD", child: Text("USD \$")),
                            DropdownMenuItem(value: "EUR", child: Text("EUR €")),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _currency = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Primary Transport Mode
              Text("Primary Mode of Transport", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _transportMode,
                items: _transportOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _transportMode = v);
                },
              ),
              const SizedBox(height: 16),

              // Overall Description
              Text("Overall Trip Story / Route Summary", style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Summary of your total itinerary, route taken, road conditions, and general takeaways...",
                ),
              ),
              const SizedBox(height: 28),

              // Step 2: Places Visited List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("2. Places Visited (${draftState.places.length})", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.sunsetAmber,
                      side: const BorderSide(color: AppColors.sunsetAmber),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _addPlace,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: Text("+ Add Place", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (draftState.places.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.map_rounded, size: 44, color: AppColors.sunsetAmber),
                      const SizedBox(height: 10),
                      Text("No places added yet", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        "Add destinations visited during this journey to record your specific experiences.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addPlace,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add First Destination"),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: draftState.places.length,
                  onReorder: (oldIdx, newIdx) => ref.read(addTripDraftProvider.notifier).reorderPlaces(oldIdx, newIdx),
                  itemBuilder: (context, index) {
                    final place = draftState.places[index];
                    return Container(
                      key: ValueKey(place),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.sunsetAmber,
                          foregroundColor: Colors.white,
                          child: Text("${index + 1}", style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
                        ),
                        title: Text(place.displayName, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.displaySubtitle, style: GoogleFonts.inter(fontSize: 11)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: AppColors.alertAmber),
                                const SizedBox(width: 2),
                                Text("${place.rating}/5", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 11)),
                                if (place.expenseAmount != null) ...[
                                  const SizedBox(width: 8),
                                  Text("•  ${place.currency} ${place.expenseAmount!.toStringAsFixed(0)}", style: GoogleFonts.inter(fontSize: 11, color: AppColors.positiveGreen, fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editPlace(index, place),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.challengeRed),
                              onPressed: () => ref.read(addTripDraftProvider.notifier).removePlace(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),

              // Bottom CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _proceedToPreview,
                  icon: const Icon(Icons.visibility_rounded, size: 20),
                  label: Text("Preview Trip & Publish", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
