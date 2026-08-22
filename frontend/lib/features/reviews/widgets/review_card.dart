import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/models/models.dart';

class ReviewCard extends StatefulWidget {
  final ReviewFeedItemModel reviewItem;

  const ReviewCard({super.key, required this.reviewItem});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> with SingleTickerProviderStateMixin {
  void _showOriginalExperienceBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.reviewItem;
    final raw = item.rawLayer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCardElevated : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ListView(
                controller: scrollController,
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetAmber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_edu_rounded, size: 16, color: AppColors.sunsetAmber),
                            const SizedBox(width: 6),
                            Text(
                              "LAYER 2: UNALTERED RAW EXPERIENCE",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.sunsetAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Author Details & Timestamp
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.sunsetAmber.withValues(alpha: 0.2),
                        backgroundImage: item.author.avatarUrl != null
                            ? NetworkImage(item.author.avatarUrl!)
                            : null,
                        child: item.author.avatarUrl == null
                            ? Text(
                                item.author.username.isNotEmpty
                                    ? item.author.username.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunsetAmber),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "@${item.author.username}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              "Visited on ${raw.visitDate} • Submitted ${DateFormat.yMMMd().format(item.createdAt)}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Rating Bar
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.alertAmber,
                        size: 24,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Exact Raw Text Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: SelectableText(
                      raw.originalText,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        height: 1.6,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metadata Details Grid
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (raw.expenseAmount != null)
                        _buildDetailChip(
                          icon: Icons.payments_outlined,
                          label: "Recorded Expense",
                          value: "${raw.currency} ${raw.expenseAmount!.toStringAsFixed(0)}",
                          isDark: isDark,
                        ),
                      if (raw.transportMode != null && raw.transportMode!.isNotEmpty)
                        _buildDetailChip(
                          icon: Icons.directions_transit_filled_outlined,
                          label: "Transport",
                          value: raw.transportMode!,
                          isDark: isDark,
                        ),
                      if (raw.groupSize != null)
                        _buildDetailChip(
                          icon: Icons.people_alt_outlined,
                          label: "Group Size",
                          value: "${raw.groupSize} Travelers",
                          isDark: isDark,
                        ),
                      if (raw.startingLocation != null && raw.startingLocation!.isNotEmpty)
                        _buildDetailChip(
                          icon: Icons.trip_origin_rounded,
                          label: "Started From",
                          value: raw.startingLocation!,
                          isDark: isDark,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Uncompressed Media Gallery
                  if (raw.photos.isNotEmpty) ...[
                    Text(
                      "Uncompressed Media (${raw.photos.length})",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: raw.photos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, photoIndex) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              raw.photos[photoIndex],
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 140,
                                height: 140,
                                color: isDark ? AppColors.darkCard : Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported_rounded),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.sunsetAmber),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
              ),
              Text(
                value,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = widget.reviewItem;
    final ai = item.aiLayer;
    final raw = item.rawLayer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If from a multi-destination trip, show trip origin banner
            if (item.tripTitle != null && item.tripTitle!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.sunsetAmber.withOpacity(isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flight_takeoff_rounded, size: 14, color: AppColors.sunsetAmber),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "Part of Trip: ${item.tripTitle!}",
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sunsetAmber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Header: Author, Rating, and AI Processing Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.sunsetAmber.withValues(alpha: 0.15),
                  backgroundImage: item.author.avatarUrl != null
                      ? NetworkImage(item.author.avatarUrl!)
                      : null,
                  child: item.author.avatarUrl == null
                      ? Text(
                          item.author.username.isNotEmpty
                              ? item.author.username.substring(0, 1).toUpperCase()
                              : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.sunsetAmber),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              "@${item.author.username}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Rating Stars
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < item.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: AppColors.alertAmber,
                                size: 14,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd().format(item.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // AI Travel Summary Pill Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                      const SizedBox(width: 4),
                      Text(
                        "AI SYNTHESIS",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // LAYER 1: AI Summary Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated.withOpacity(0.6) : AppColors.lightCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder.withOpacity(0.5) : AppColors.lightBorder,
                ),
              ),
              child: Text(
                ai.summary,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bulleted Highlights (Green Tint)
            if (ai.highlights.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ai.highlights.map((h) {
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
                          const Icon(Icons.check_circle_rounded, color: AppColors.positiveGreen, size: 14),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              h,
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
              ),
            ],

            // Bulleted Challenges & Alerts (Amber/Red Tint)
            if (ai.challenges.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ai.challenges.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.alertAmberBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.alertAmber.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.alertAmber, size: 14),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              c,
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
              ),
            ],

            // Metadata Pill Tags: Cost/Person, Transport, Group
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (ai.extractedBudgetPerPerson != null || raw.expenseAmount != null)
                  _buildMetadataPill(
                    icon: Icons.wallet_rounded,
                    label: "${raw.currency} ${(ai.extractedBudgetPerPerson ?? raw.expenseAmount)!.toStringAsFixed(0)} / person",
                    isDark: isDark,
                  ),
                if (raw.transportMode != null && raw.transportMode!.isNotEmpty)
                  _buildMetadataPill(
                    icon: Icons.two_wheeler_rounded,
                    label: raw.transportMode!,
                    isDark: isDark,
                  ),
                if (raw.groupSize != null)
                  _buildMetadataPill(
                    icon: Icons.groups_rounded,
                    label: "${raw.groupSize} Travelers",
                    isDark: isDark,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // INTERACTIVE ACTION BUTTON: View Original Experience
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: isDark ? AppColors.darkCardElevated.withOpacity(0.3) : AppColors.lightCardElevated,
                ),
                onPressed: () => _showOriginalExperienceBottomSheet(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.sunsetAmber),
                    const SizedBox(width: 8),
                    Text(
                      "View Original Experience (Layer 2)",
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataPill({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
