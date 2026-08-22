import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/network/api_service.dart';
import '../locations/location_detail_screen.dart';

class ChatMessage {
  final bool isUser;
  final String text;
  final AIAssistantResponseModel? responseData;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    this.responseData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  double? _budgetMax;
  String _currency = "INR";

  final List<String> _suggestedPrompts = [
    "Budget motorcycle trip under ₹1000 from Mumbai",
    "Monsoon fort treks with scenic valley views",
    "Peaceful sunset beaches with cliff cafes",
    "High altitude monasteries for serene road trips",
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _messages.add(
      ChatMessage(
        isUser: false,
        text: "Hello explorer! 🧭 I am your **WanderLust Copilot**.\n\n"
            "Ask me anything about budget road trips, monsoon treks, road conditions, or hidden destinations. "
            "Every recommendation is grounded in verified traveler reviews with explicit citations!",
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final queryText = presetText ?? _queryController.text.trim();
    if (queryText.isEmpty || _isLoading) return;

    if (presetText == null) {
      _queryController.clear();
    }

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: queryText));
      _isLoading = true;
    });
    _scrollToBottom();

    final api = ref.read(apiServiceProvider);

    // Build chat history from prior messages (skip the welcome msg at index 0)
    final List<Map<String, String>> historyForApi = [];
    for (int i = 1; i < _messages.length - 1; i++) {
      final m = _messages[i];
      // Only include the last 10 turns to keep context window manageable
      if (_messages.length - 1 - i <= 10) {
        historyForApi.add({
          'role': m.isUser ? 'user' : 'model',
          'text': m.text,
        });
      }
    }

    try {
      final response = await api.queryAssistant(
        query: queryText,
        budgetMax: _budgetMax,
        currency: _currency,
        chatHistory: historyForApi.isNotEmpty ? historyForApi : null,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          text: response.answer,
          responseData: response,
        ));
        _isLoading = false;
      });
    } catch (e) {
      final errorStr = e.toString().replaceAll('Exception: ', '');
      final isTimeout = errorStr.toLowerCase().contains('timeout') || errorStr.toLowerCase().contains('timed out');
      
      final displayError = isTimeout
          ? "⏱️ Request timed out while connecting to the travel AI engine. Please verify your connection or try again."
          : "⚠️ $errorStr";

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.challengeRed,
            content: Text(displayError),
            action: SnackBarAction(
              label: "Retry",
              textColor: Colors.white,
              onPressed: () => _handleSend(queryText),
            ),
          ),
        );
      }
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          text: "$displayError\n\n_Tip: You can retry your question or rephrase it._",
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.electricViolet, Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              "Wanderlust Copilot",
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Filter button for budget
          IconButton(
            icon: Icon(
              _budgetMax != null ? Icons.filter_alt_rounded : Icons.tune_rounded,
              color: _budgetMax != null ? AppColors.sunsetAmber : null,
            ),
            onPressed: () => _showFilterDialog(context, isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          // Suggested Prompt Chips (if few messages)
          if (_messages.length <= 2)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final prompt = _suggestedPrompts[idx];
                  return ActionChip(
                    backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                    side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.sunsetAmber),
                    label: Text(
                      prompt,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    onPressed: () => _handleSend(prompt),
                  );
                },
              ),
            ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.sunsetAmber),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Synthesizing verified community reviews...",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              border: Border(
                top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      decoration: InputDecoration(
                        hintText: _budgetMax != null
                            ? "Ask within ${_currency} ${_budgetMax!.toStringAsFixed(0)}..."
                            : "Ask e.g. 'Best weekend bike trek under ₹800'",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: _isLoading ? null : () => _handleSend(),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.sunsetAmber,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sunsetAmber,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Assistant Bubble
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assistant Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.electricViolet),
              const SizedBox(width: 6),
              Text(
                "WANDERLUST RAG ENGINE",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.electricViolet,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Markdown / Answer text
          Text(
            msg.text,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),

          // Grounded Citations Section
          if (msg.responseData != null && msg.responseData!.citations.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              "Verified Community Citations:",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.sunsetAmber,
              ),
            ),
            const SizedBox(height: 8),
            ...msg.responseData!.citations.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "📍 ${c.locationName} • @${c.authorUsername}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.alertAmber),
                            Text("${c.rating}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\"${c.quoteSnippet}\"",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          // Recommended Destination Cards
          if (msg.responseData != null && msg.responseData!.recommendedLocations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Suggested Destinations:",
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: msg.responseData!.recommendedLocations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final loc = msg.responseData!.recommendedLocations[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocationDetailScreen(initialLocation: loc),
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.sunsetAmber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "${loc.city ?? loc.country} • ${loc.placeType}",
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.sunsetAmber),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "View Feed →",
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              if (loc.averageRating != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: AppColors.alertAmber),
                                    Text("${loc.averageRating}", style: const TextStyle(fontSize: 11)),
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
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, bool isDark) {
    final budgetCtrl = TextEditingController(text: _budgetMax?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Assistant Constraints", style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Max Budget / Person",
                  hintText: "e.g. 1000",
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: "Currency"),
                items: ["INR", "USD", "EUR"].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _currency = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _budgetMax = null);
                Navigator.pop(ctx);
              },
              child: const Text("Reset"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _budgetMax = double.tryParse(budgetCtrl.text.trim());
                });
                Navigator.pop(ctx);
              },
              child: const Text("Apply"),
            ),
          ],
        );
      },
    );
  }
}
