import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/auth_guard.dart';

class AddLocationExperienceScreen extends ConsumerStatefulWidget {
  final TripPlaceDraftModel draftPlace;

  const AddLocationExperienceScreen({super.key, required this.draftPlace});

  @override
  ConsumerState<AddLocationExperienceScreen> createState() => _AddLocationExperienceScreenState();
}

class _AddLocationExperienceScreenState extends ConsumerState<AddLocationExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _rating;
  late TextEditingController _experienceCtrl;
  late TextEditingController _expenseCtrl;
  late TextEditingController _tipsCtrl;
  late String _currency;
  String _transportMode = "Car / Cab";
  List<String> _localImagePaths = [];

  final ImagePicker _picker = ImagePicker();
  static const int _maxPhotos = 10;

  final List<String> _transportOptions = [
    "Car / Cab",
    "Motorcycle / Scooter",
    "Train / Metro",
    "Bus / Public Transport",
    "Flight",
    "Trekking / Walking",
  ];

  @override
  void initState() {
    super.initState();
    _rating = widget.draftPlace.rating;
    _experienceCtrl = TextEditingController(text: widget.draftPlace.rawExperience);
    _expenseCtrl = TextEditingController(
      text: widget.draftPlace.expenseAmount != null ? widget.draftPlace.expenseAmount!.toStringAsFixed(0) : "",
    );
    _tipsCtrl = TextEditingController(text: widget.draftPlace.tips ?? "");
    _currency = widget.draftPlace.currency;
    _localImagePaths = List<String>.from(widget.draftPlace.localImagePaths);
    if (widget.draftPlace.transportMode != null && _transportOptions.contains(widget.draftPlace.transportMode)) {
      _transportMode = widget.draftPlace.transportMode!;
    }
  }

  @override
  void dispose() {
    _experienceCtrl.dispose();
    _expenseCtrl.dispose();
    _tipsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickMultipleImages() async {
    AuthGuard.requireAuth(
      context: context,
      ref: ref,
      actionTitle: "Upload Travel Photos",
      actionDescription: "Sign up or log in to attach photos and share visual memories with the community.",
      onAuthenticated: () async {
        try {
          final List<XFile> picked = await _picker.pickMultiImage(
            imageQuality: 85,
            maxWidth: 1920,
            maxHeight: 1920,
          );

          if (picked.isNotEmpty) {
            final availableSlots = _maxPhotos - _localImagePaths.length;
            final filesToAdd = picked.take(availableSlots).map((f) => f.path).toList();

            setState(() {
              _localImagePaths.addAll(filesToAdd);
            });

            if (picked.length > availableSlots && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.alertAmber,
                  content: Text("Maximum $_maxPhotos photos allowed per stop. Added $availableSlots."),
                ),
              );
            }
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.challengeRed,
                content: Text("Could not pick images: $e"),
              ),
            );
          }
        }
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _localImagePaths.removeAt(index);
    });
  }

  void _saveExperience() {
    if (!_formKey.currentState!.validate()) return;

    widget.draftPlace.rating = _rating;
    widget.draftPlace.rawExperience = _experienceCtrl.text.trim();
    widget.draftPlace.expenseAmount = double.tryParse(_expenseCtrl.text.trim());
    widget.draftPlace.currency = _currency;
    widget.draftPlace.transportMode = _transportMode;
    widget.draftPlace.tips = _tipsCtrl.text.trim().isNotEmpty ? _tipsCtrl.text.trim() : null;
    widget.draftPlace.localImagePaths = _localImagePaths;

    Navigator.pop(context, widget.draftPlace);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Place Experience", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sunsetAmber.withOpacity(isDark ? 0.2 : 0.1),
                      AppColors.amberLight.withOpacity(isDark ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop_rounded, color: AppColors.sunsetAmber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.draftPlace.displayName,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            widget.draftPlace.displaySubtitle,
                            style: GoogleFonts.inter(fontSize: 12.5, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Star Rating
              Text("How was your experience here?", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    icon: Icon(
                      starNum <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 36,
                      color: AppColors.alertAmber,
                    ),
                    onPressed: () => setState(() => _rating = starNum),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Detailed Experience text
              Text("Experience & Highlights", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _experienceCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "e.g. Darshan took approx 2 hours. The morning weather was serene, roads were smooth, and food near the temple was delicious...",
                ),
                validator: (val) => (val == null || val.trim().length < 5) ? "Please share at least a few words" : null,
              ),
              const SizedBox(height: 20),

              // MULTIPLE PHOTO SELECTION SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Attach Photos", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(
                        "${_localImagePaths.length} / $_maxPhotos photos selected",
                        style: GoogleFonts.inter(fontSize: 11.5, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                      ),
                    ],
                  ),
                  if (_localImagePaths.length < _maxPhotos)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sunsetAmber,
                        side: const BorderSide(color: AppColors.sunsetAmber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _pickMultipleImages,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: Text("+ Add Photos", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Photo Thumbnails Strip
              if (_localImagePaths.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _localImagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final path = _localImagePaths[index];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 100,
                                color: isDark ? AppColors.darkCard : Colors.grey.shade300,
                                child: const Icon(Icons.broken_image_rounded),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.challengeRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Expenses & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Expense at this stop", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expenseCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "e.g. 800",
                            prefixIcon: Icon(Icons.currency_rupee_rounded, size: 18),
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
                        Text("Currency", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
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
              const SizedBox(height: 18),

              // Transport Mode
              Text("Transport Used to Reach Here", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _transportMode,
                items: _transportOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _transportMode = v);
                },
              ),
              const SizedBox(height: 18),

              // Practical Tips
              Text("Traveler Tip (Optional)", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tipsCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: "e.g. Arrive before 7 AM to avoid the long darshan queue. Ample paid parking available.",
                  prefixIcon: Icon(Icons.lightbulb_outline_rounded, color: AppColors.sunsetAmber),
                ),
              ),
              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveExperience,
                  child: Text("Save Experience", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
