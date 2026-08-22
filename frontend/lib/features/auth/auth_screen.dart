import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../home/home_screen.dart';
import 'auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool returnOnSuccess;

  const AuthScreen({super.key, this.returnOnSuccess = false});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;

  // Form Keys & Controllers
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _setSignUpMode(bool isSignUp) {
    if (_isSignUp == isSignUp) return;
    setState(() {
      _isSignUp = isSignUp;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    bool success = false;
    if (_isSignUp) {
      success = await ref.read(authProvider.notifier).register(
            _emailCtrl.text.trim(),
            _usernameCtrl.text.trim(),
            _passwordCtrl.text.trim(),
            fullName: _fullNameCtrl.text.trim().isNotEmpty ? _fullNameCtrl.text.trim() : null,
          );
    } else {
      success = await ref.read(authProvider.notifier).login(
            _emailCtrl.text.trim(),
            _passwordCtrl.text.trim(),
          );
    }

    if (success && mounted) {
      if (widget.returnOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.challengeRed,
            content: Text(error),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      if (widget.returnOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.challengeRed,
            content: Text(error),
          ),
        );
      }
    }
  }

  Future<void> _handleContinueAsGuest() async {
    await ref.read(authProvider.notifier).continueAsGuest();
    if (mounted) {
      if (widget.returnOnSuccess) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: "Toggle OLED Dark / Light Mode",
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.alertAmber : AppColors.electricViolet,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. BRANDING HEADER
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sunsetAmber, AppColors.amberLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sunsetAmber.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "WanderLust",
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Discover curated journeys with AI",
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. ERROR BANNER (IF ANY)
                  if (authState.errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.challengeRedBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.challengeRed.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.challengeRed, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.challengeRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. CREDENTIALS CARD CONTAINER
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // A. ANIMATED SEGMENTED SLIDING PILL TOGGLE
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final tabWidth = constraints.maxWidth / 2;
                                return Stack(
                                  children: [
                                    // Animated Active Indicator Pill (Exactly 50% width)
                                    AnimatedAlign(
                                      duration: const Duration(milliseconds: 220),
                                      curve: Curves.easeInOutCubic,
                                      alignment: _isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        width: tabWidth,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.sunsetAmber,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.sunsetAmber.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Equal-width interactive buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () => _setSignUpMode(false),
                                            child: Center(
                                              child: AnimatedDefaultTextStyle(
                                                duration: const Duration(milliseconds: 200),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.5,
                                                  fontWeight: !_isSignUp ? FontWeight.w800 : FontWeight.w600,
                                                  color: !_isSignUp
                                                      ? Colors.white
                                                      : (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575)),
                                                ),
                                                child: const Text("Sign In"),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () => _setSignUpMode(true),
                                            child: Center(
                                              child: AnimatedDefaultTextStyle(
                                                duration: const Duration(milliseconds: 200),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14.5,
                                                  fontWeight: _isSignUp ? FontWeight.w800 : FontWeight.w600,
                                                  color: _isSignUp
                                                      ? Colors.white
                                                      : (isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575)),
                                                ),
                                                child: const Text("Create Account"),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // B. FORM INPUT FIELDS
                          // Email / Username Field
                          _buildFieldLabel(_isSignUp ? "Email Address" : "Email or Username", isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: _buildInputDecoration(
                              hintText: _isSignUp ? "explorer@wanderlust.ai" : "rohan_travels or email",
                              prefixIcon: Icons.email_outlined,
                              isDark: isDark,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Please enter email or username";
                              if (_isSignUp && (!val.contains('@') || !val.contains('.'))) {
                                return "Please enter a valid email address";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Additional Sign Up Fields (Username & Full Name)
                          if (_isSignUp) ...[
                            _buildFieldLabel("Username", isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _usernameCtrl,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: _buildInputDecoration(
                                hintText: "e.g. wanderer_sam",
                                prefixIcon: Icons.alternate_email_rounded,
                                isDark: isDark,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length < 3) {
                                  return "Username must be at least 3 characters";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildFieldLabel("Full Name (Optional)", isDark),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _fullNameCtrl,
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: _buildInputDecoration(
                                hintText: "e.g. Sam Explorer",
                                prefixIcon: Icons.badge_outlined,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Password Field
                          _buildFieldLabel("Password", isDark),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: _buildInputDecoration(
                              hintText: _isSignUp ? "At least 6 characters" : "••••••••",
                              prefixIcon: Icons.lock_outline_rounded,
                              isDark: isDark,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return "Please enter your password";
                              if (_isSignUp && val.trim().length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // C. PRIMARY SUBMIT BUTTON (Sign In / Create Account)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sunsetAmber,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                                    )
                                  : Text(
                                      _isSignUp ? "Create Account" : "Sign In",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // D. ELEGANT DIVIDER "OR"
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                child: Text(
                                  "OR",
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // E. GOOGLE SIGN-IN BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                side: BorderSide(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: isDark ? AppColors.darkCardElevated.withValues(alpha: 0.4) : Colors.white,
                              ),
                              onPressed: authState.isLoading ? null : _handleGoogleSignIn,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleLogoWidget(size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Continue with Google",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // F. CONTINUE AS GUEST BUTTON (IF NOT MODAL GATE)
                          if (!widget.returnOnSuccess) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  side: BorderSide(
                                    color: isDark ? AppColors.darkBorder.withValues(alpha: 0.7) : AppColors.lightBorder,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  backgroundColor: isDark ? AppColors.darkBackground.withValues(alpha: 0.5) : AppColors.lightCardElevated,
                                ),
                                onPressed: authState.isLoading ? null : _handleContinueAsGuest,
                                icon: const Icon(Icons.explore_outlined, size: 18, color: AppColors.sunsetAmber),
                                label: Text(
                                  "Explore as Guest",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. FOOTER TOGGLE LINK
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUp ? "Already have an account?" : "Don't have an account?",
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: authState.isLoading ? null : () => _setSignUpMode(!_isSignUp),
                        child: Text(
                          _isSignUp ? "Sign In" : "Sign Up",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.sunsetAmber,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 13.5,
        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      ),
      filled: true,
      fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(
        prefixIcon,
        size: 20,
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.sunsetAmber,
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.challengeRed,
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.challengeRed,
          width: 1.8,
        ),
      ),
    );
  }
}

/// Official 4-color Google G-Logo vector widget rendered natively.
class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.78);

    // Top Red arc
    canvas.drawArc(rect, -2.4, 1.4, false, redPaint);
    // Left Yellow arc
    canvas.drawArc(rect, 2.2, 1.3, false, yellowPaint);
    // Bottom Green arc
    canvas.drawArc(rect, 0.7, 1.5, false, greenPaint);
    // Right Blue arc
    canvas.drawArc(rect, -1.0, 1.7, false, bluePaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - w * 0.05, center.dy - h * 0.11, w * 0.48, h * 0.22),
        const Radius.circular(2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
