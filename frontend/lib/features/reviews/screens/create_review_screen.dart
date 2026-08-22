import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_service.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final LocationModel location;

  const CreateReviewScreen({super.key, required this.location});

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  int _rating = 5;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _startingLocationController = TextEditingController();

  String _currency = "INR";
  int _groupSize = 2;
  String _transportMode = "Motorcycle";
  DateTime _visitDate = DateTime.now();
  final List<String> _localImagePaths = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  static const int _maxPhotos = 10;

  final List<String> _transportModes = [
    "Motorcycle",
    "Car / Cab",
    "Public Bus",
    "Train",
    "Trekking / Walking",
    "Bicycle",
    "Flight",
  ];

  final List<String> _currencies = ["INR", "USD", "EUR", "GBP", "AED"];

  @override
  void dispose() {
    _textController.dispose();
    _expenseController.dispose();
    _startingLocationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        final available = _maxPhotos - _localImagePaths.length;
        setState(() {
          _localImagePaths.addAll(picked.take(available).map((f) => f.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.challengeRed, content: Text("Could not pick photos: $e")),
        );
      }
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider);

    try {
      // 1. Upload local images if any
      List<String> uploadedUrls = [];
      if (_localImagePaths.isNotEmpty) {
        uploadedUrls = await api.uploadMediaFiles(_localImagePaths);
      }

      final double? expense = _expenseController.text.isNotEmpty
          ? double.tryParse(_expenseController.text.trim())
          : null;

      final res = await api.submitReview(
        locationId: widget.location.id,
        rating: _rating,
        originalText: _textController.text.trim(),
        visitDate: DateFormat('yyyy-MM-dd').format(_visitDate),
        expenseAmount: expense,
        currency: _currency,
        groupSize: _groupSize,
        transportMode: _transportMode,
        startingLocation: _startingLocationController.text.trim().isNotEmpty
            ? _startingLocationController.text.trim()
            : null,
        photoUrls: uploadedUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.positiveGreen,
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Review & photos saved! Background AI analysis pending.",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.challengeRed,
            content: Text("Error submitting review: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Share Travel Experience", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Destination Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded, color: AppColors.sunsetAmber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.location.name,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "${widget.location.city ?? widget.location.stateRegion ?? ''}, ${widget.location.country}",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rating Section
              Text("Overall Rating", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = starVal),
                    icon: Icon(
                      starVal <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.alertAmber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Experience Text (Raw Text)
              Text("Your Authentic Experience", style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                "Mention road condition, crowds, expenses, food, or tips. AI will extract structured summaries automatically without altering your raw text.",
                style: GoogleFonts.inter(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "e.g. Place mast tha, road kharab thi but view worth it. ₹700 per person laga Mumbai se bike pe...",
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 5) {
                    return "Please write at least 5 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Photo Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Attach Photos (${_localImagePaths.length} / $_maxPhotos)",
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (_localImagePaths.length < _maxPhotos)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sunsetAmber,
                        side: const BorderSide(color: AppColors.sunsetAmber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
                      label: Text("+ Add Photos", style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_localImagePaths.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _localImagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_localImagePaths[idx]),
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: InkWell(
                              onTap: () => setState(() => _localImagePaths.removeAt(idx)),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: AppColors.challengeRed, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
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

              // Expense & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Expense / Person", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _expenseController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "700",
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20),
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
                        Text("Currency", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _currency,
                          decoration: const InputDecoration(),
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _currency = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transport Mode & Group Size
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Transport Mode", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _transportMode,
                          decoration: const InputDecoration(),
                          items: _transportModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _transportMode = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Group Size", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _groupSize > 1 ? () => setState(() => _groupSize--) : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text("$_groupSize", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
                            IconButton(
                              onPressed: () => setState(() => _groupSize++),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Starting Location
              Text("Starting City / Point", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _startingLocationController,
                decoration: const InputDecoration(
                  hintText: "e.g. Mumbai, Pune, Bangalore",
                  prefixIcon: Icon(Icons.trip_origin_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "Submit Experience",
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
