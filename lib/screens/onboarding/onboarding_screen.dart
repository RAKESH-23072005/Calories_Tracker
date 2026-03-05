import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _contentAnimController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      illustration: _IllustrationType.food,
      title: 'Know What You Eat',
      description:
          'Gain insights in your nutritional habits with detailed statistics',
    ),
    _OnboardingData(
      illustration: _IllustrationType.tracking,
      title: 'Track Your Diet',
      description:
          'We will help you lose weight, stay fit, or build muscle',
    ),
    _OnboardingData(
      illustration: _IllustrationType.healthy,
      title: 'Live Healthy & Great',
      description:
          "Let's start this journey and live healthy together!",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentAnimController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _contentAnimController, curve: Curves.easeOutCubic),
    );
    _contentAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _contentAnimController.reset();
    _contentAnimController.forward();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: logo + skip/login
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Mini logo
                  const _MiniAppleLogo(),
                  // Skip or Login button
                  if (!isLastPage)
                    GestureDetector(
                      onTap: _skip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _completeOnboarding,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _OnboardingPage(
                    data: _pages[index],
                    fadeAnimation: _contentFade,
                    slideAnimation: _contentSlide,
                  );
                },
              ),
            ),

            // Bottom: dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
              child: Column(
                children: [
                  // Page indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _DotIndicator(
                        isActive: index == _currentPage,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next / Start button
                  _NextButton(
                    isLastPage: isLastPage,
                    onTap: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data Model ─────────────────────────────────────────────────────────────

enum _IllustrationType { food, tracking, healthy }

class _OnboardingData {
  final _IllustrationType illustration;
  final String title;
  final String description;

  const _OnboardingData({
    required this.illustration,
    required this.title,
    required this.description,
  });
}

// ─── Page Widget ────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const _OnboardingPage({
    required this.data,
    required this.fadeAnimation,
    required this.slideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),
          // Illustration
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            child: _buildIllustration(data.illustration),
          ),
          const Spacer(flex: 1),
          // Title & description with animation
          FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textTertiary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildIllustration(_IllustrationType type) {
    return CustomPaint(
      size: const Size(280, 280),
      painter: switch (type) {
        _IllustrationType.food => _FoodIllustrationPainter(),
        _IllustrationType.tracking => _TrackingIllustrationPainter(),
        _IllustrationType.healthy => _HealthyIllustrationPainter(),
      },
    );
  }
}

// ─── Dot Indicator ──────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final bool isActive;
  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryGreen
            : AppTheme.primaryGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Next / Start Button ────────────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  final bool isLastPage;
  final VoidCallback onTap;
  const _NextButton({required this.isLastPage, required this.onTap});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return ScaleTransition(scale: animation, child: child);
      },
      child: widget.isLastPage
          ? _buildStartButton()
          : _buildNextArrow(),
    );
  }

  Widget _buildNextArrow() {
    return GestureDetector(
      key: const ValueKey('next'),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.05);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppTheme.primaryGreen,
                  width: 2.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.primaryGreen,
                  size: 22,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      key: const ValueKey('start'),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'Start',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── LifeFit Logo ───────────────────────────────────────────────────────────

class _MiniAppleLogo extends StatelessWidget {
  const _MiniAppleLogo();

  @override
  Widget build(BuildContext context) {
    return const LifeFitLogo(size: 36, color: AppTheme.primaryGreen);
  }
}

/// A custom-drawn LifeFit logo — apple-heart with pulse line + leaf.
/// Works on any background (no image dependency).
class LifeFitLogo extends StatelessWidget {
  final double size;
  final Color color;
  final Color? pulseColor;
  const LifeFitLogo({
    super.key,
    required this.size,
    this.color = Colors.white,
    this.pulseColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LifeFitLogoPainter(
        color: color,
        pulseColor: pulseColor,
      ),
    );
  }
}

class _LifeFitLogoPainter extends CustomPainter {
  final Color color;
  final Color? pulseColor;
  _LifeFitLogoPainter({required this.color, this.pulseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Heart / apple body (filled) ──
    final heartPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final heartPath = Path();
    // Bottom point
    heartPath.moveTo(w * 0.5, h * 0.88);
    // Left side curve
    heartPath.cubicTo(
      w * 0.12, h * 0.68,
      w * 0.02, h * 0.38,
      w * 0.22, h * 0.28,
    );
    // Top-left bump
    heartPath.cubicTo(
      w * 0.35, h * 0.20,
      w * 0.45, h * 0.24,
      w * 0.5, h * 0.35,
    );
    // Top-right bump
    heartPath.cubicTo(
      w * 0.55, h * 0.24,
      w * 0.65, h * 0.20,
      w * 0.78, h * 0.28,
    );
    // Right side curve
    heartPath.cubicTo(
      w * 0.98, h * 0.38,
      w * 0.88, h * 0.68,
      w * 0.5, h * 0.88,
    );
    heartPath.close();
    canvas.drawPath(heartPath, heartPaint);

    // ── Pulse / heartbeat line ──
    // Auto-contrast: green on white heart, white on green heart
    final resolvedPulseColor = pulseColor ??
        (color == Colors.white ? AppTheme.primaryGreen : Colors.white);

    final pulsePaint = Paint()
      ..color = resolvedPulseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pulsePath = Path();
    pulsePath.moveTo(w * 0.16, h * 0.50);
    pulsePath.lineTo(w * 0.30, h * 0.50);
    pulsePath.lineTo(w * 0.37, h * 0.38);
    pulsePath.lineTo(w * 0.46, h * 0.62);
    pulsePath.lineTo(w * 0.54, h * 0.42);
    pulsePath.lineTo(w * 0.62, h * 0.55);
    pulsePath.lineTo(w * 0.70, h * 0.50);
    pulsePath.lineTo(w * 0.84, h * 0.50);
    canvas.drawPath(pulsePath, pulsePaint);

    // ── Leaf at top-center (no stem) ──
    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Leaf shape — large, fully covers top-right bump
    final leafPath = Path();
    leafPath.moveTo(w * 0.46, h * 0.32);
    leafPath.quadraticBezierTo(w * 0.62, h * 0.02, w * 0.88, h * 0.10);
    leafPath.quadraticBezierTo(w * 0.82, h * 0.36, w * 0.46, h * 0.32);
    leafPath.close();
    canvas.drawPath(leafPath, leafPaint);

    // Leaf vein
    final veinPaint = Paint()
      ..color = resolvedPulseColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.53, h * 0.26),
      Offset(w * 0.70, h * 0.15),
      veinPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Illustration Painters ──────────────────────────────────────────────────

/// Page 1: Food / Plate illustration
class _FoodIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    // Plate (light circle)
    final platePaint = Paint()
      ..color = const Color(0xFFF0F7F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r, platePaint);

    // Plate rim
    final rimPaint = Paint()
      ..color = const Color(0xFFD5E8DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(cx, cy), r, rimPaint);
    canvas.drawCircle(Offset(cx, cy), r * 0.88, rimPaint..strokeWidth = 1);

    // Egg 1
    _drawEgg(canvas, Offset(cx - r * 0.3, cy - r * 0.15), r * 0.25);
    // Egg 2
    _drawEgg(canvas, Offset(cx + r * 0.25, cy - r * 0.2), r * 0.22);

    // Avocado half
    _drawAvocado(canvas, Offset(cx + r * 0.3, cy + r * 0.35), r * 0.28);

    // Berries cluster
    _drawBerries(canvas, Offset(cx - r * 0.35, cy + r * 0.35), r * 0.12);

    // Leaf garnish
    _drawLeafGarnish(canvas, Offset(cx, cy - r * 0.45), r * 0.18);

    // Small tomato slices
    _drawTomatoSlice(canvas, Offset(cx + r * 0.05, cy + r * 0.1), r * 0.1);
  }

  void _drawEgg(Canvas canvas, Offset center, double radius) {
    // White
    final whitePaint = Paint()
      ..color = const Color(0xFFFFF8E9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 2),
      whitePaint,
    );
    // White border
    canvas.drawOval(
      Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 2),
      Paint()
        ..color = const Color(0xFFE8DCC0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Yolk
    final yolkPaint = Paint()
      ..color = const Color(0xFFFF9F43)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, yolkPaint);
    // Yolk highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.15, center.dy - radius * 0.15),
      radius * 0.15,
      Paint()..color = const Color(0xFFFFBB70),
    );
  }

  void _drawAvocado(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF8BC34A)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.addOval(
        Rect.fromCenter(center: center, width: radius * 1.8, height: radius * 2.2));
    canvas.drawPath(path, paint);

    // Darker skin
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5D8A2D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Inner lighter part
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(center.dx, center.dy + radius * 0.05),
          width: radius * 1.2,
          height: radius * 1.5),
      Paint()..color = const Color(0xFFC5E1A5),
    );

    // Pit
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.1),
      radius * 0.32,
      Paint()..color = const Color(0xFF8D6E3E),
    );
  }

  void _drawBerries(Canvas canvas, Offset center, double radius) {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFFD32F2F),
      const Color(0xFFEF5350),
    ];
    final offsets = [
      Offset(center.dx - radius * 0.6, center.dy),
      Offset(center.dx + radius * 0.6, center.dy),
      Offset(center.dx, center.dy - radius * 0.7),
    ];
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        offsets[i],
        radius * 0.55,
        Paint()..color = colors[i],
      );
      // Tiny highlight
      canvas.drawCircle(
        Offset(offsets[i].dx - radius * 0.12, offsets[i].dy - radius * 0.12),
        radius * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }
  }

  void _drawLeafGarnish(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(center.dx, center.dy + radius);
    path.quadraticBezierTo(
        center.dx - radius * 0.8, center.dy - radius * 0.2,
        center.dx, center.dy - radius);
    path.quadraticBezierTo(
        center.dx + radius * 0.8, center.dy - radius * 0.2,
        center.dx, center.dy + radius);
    canvas.drawPath(path, paint);

    // Leaf vein
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.8),
      Offset(center.dx, center.dy + radius * 0.6),
      Paint()
        ..color = const Color(0xFF388E3C)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTomatoSlice(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFF7043),
    );
    canvas.drawCircle(
      center,
      radius * 0.65,
      Paint()..color = const Color(0xFFFF8A65),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE64A19)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Page 2: Tracking / Analytics illustration
class _TrackingIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background shape
    final bgPaint = Paint()
      ..color = const Color(0xFFF0F7F3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.15, w * 0.84, h * 0.7),
        const Radius.circular(24),
      ),
      bgPaint,
    );

    // Bar chart
    final barColors = [
      const Color(0xFF2DB573),
      const Color(0xFF5DD39E),
      const Color(0xFF81C784),
      const Color(0xFFFF9F43),
      const Color(0xFF2DB573),
    ];
    final barHeights = [0.45, 0.7, 0.55, 0.85, 0.62];
    final barWidth = w * 0.09;
    final chartLeft = w * 0.18;
    final chartBottom = h * 0.72;
    final chartHeight = h * 0.42;

    for (int i = 0; i < 5; i++) {
      final x = chartLeft + i * (barWidth + w * 0.06);
      final barH = chartHeight * barHeights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartBottom - barH, barWidth, barH),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = barColors[i]);
    }

    // Chart baseline
    canvas.drawLine(
      Offset(chartLeft - 10, chartBottom),
      Offset(w * 0.82, chartBottom),
      Paint()
        ..color = const Color(0xFFD5E8DD)
        ..strokeWidth = 1.5,
    );

    // Grid lines
    for (int i = 1; i <= 3; i++) {
      final y = chartBottom - (chartHeight * i / 3.5);
      canvas.drawLine(
        Offset(chartLeft - 10, y),
        Offset(w * 0.82, y),
        Paint()
          ..color = const Color(0xFFE8F0EC)
          ..strokeWidth = 0.8,
      );
    }

    // Pie chart (mini)
    final pieCenter = Offset(w * 0.72, h * 0.32);
    final pieR = w * 0.1;
    // Segment 1
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieR),
      -1.57,
      2.2,
      true,
      Paint()..color = const Color(0xFF2DB573),
    );
    // Segment 2
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieR),
      0.63,
      1.5,
      true,
      Paint()..color = const Color(0xFF5DD39E),
    );
    // Segment 3
    canvas.drawArc(
      Rect.fromCircle(center: pieCenter, radius: pieR),
      2.13,
      2.15,
      true,
      Paint()..color = const Color(0xFFA5D6A7),
    );
    // White center
    canvas.drawCircle(pieCenter, pieR * 0.45, Paint()..color = Colors.white);

    // Trend line
    final linePaint = Paint()
      ..color = const Color(0xFF2DB573)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(w * 0.15, h * 0.38);
    linePath.cubicTo(w * 0.28, h * 0.32, w * 0.35, h * 0.22, w * 0.45, h * 0.28);
    linePath.cubicTo(w * 0.52, h * 0.32, w * 0.55, h * 0.2, w * 0.62, h * 0.25);
    canvas.drawPath(linePath, linePaint);

    // Dots on trend line
    final dotPositions = [
      Offset(w * 0.15, h * 0.38),
      Offset(w * 0.35, h * 0.245),
      Offset(w * 0.45, h * 0.28),
      Offset(w * 0.62, h * 0.25),
    ];
    for (final pos in dotPositions) {
      canvas.drawCircle(pos, 4, Paint()..color = const Color(0xFF2DB573));
      canvas.drawCircle(pos, 2, Paint()..color = Colors.white);
    }

    // Person sitting
    _drawPerson(canvas, Offset(w * 0.2, h * 0.5), w * 0.12);
  }

  void _drawPerson(Canvas canvas, Offset pos, double scale) {
    final skinColor = const Color(0xFFFFD8B5);
    final hairColor = const Color(0xFF4A7C59);
    final shirtColor = const Color(0xFF1F2937);

    // Head
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - scale * 1.5),
      scale * 0.35,
      Paint()..color = skinColor,
    );

    // Hair
    final hairPath = Path();
    hairPath.addArc(
      Rect.fromCircle(
          center: Offset(pos.dx, pos.dy - scale * 1.6), radius: scale * 0.38),
      -3.14,
      3.14,
    );
    canvas.drawPath(hairPath, Paint()..color = hairColor);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy - scale * 0.7),
          width: scale * 0.7,
          height: scale * 1.1,
        ),
        const Radius.circular(6),
      ),
      Paint()..color = shirtColor,
    );

    // Arm holding tablet
    canvas.drawLine(
      Offset(pos.dx + scale * 0.35, pos.dy - scale * 1.0),
      Offset(pos.dx + scale * 0.8, pos.dy - scale * 0.8),
      Paint()
        ..color = skinColor
        ..strokeWidth = scale * 0.15
        ..strokeCap = StrokeCap.round,
    );

    // Clipboard/tablet
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx + scale * 1.0, pos.dy - scale * 0.7),
          width: scale * 0.5,
          height: scale * 0.7,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx + scale * 1.0, pos.dy - scale * 0.7),
          width: scale * 0.5,
          height: scale * 0.7,
        ),
        const Radius.circular(3),
      ),
      Paint()
        ..color = const Color(0xFFD5E8DD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Page 3: Healthy lifestyle / Trophy illustration
class _HealthyIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Background confetti/celebration shapes
    final confettiColors = [
      const Color(0xFF2DB573),
      const Color(0xFFFF9F43),
      const Color(0xFF5DD39E),
      const Color(0xFF54A0FF),
    ];
    final confettiPositions = [
      Offset(w * 0.15, h * 0.2),
      Offset(w * 0.82, h * 0.15),
      Offset(w * 0.1, h * 0.6),
      Offset(w * 0.88, h * 0.55),
      Offset(w * 0.3, h * 0.12),
      Offset(w * 0.72, h * 0.7),
    ];
    for (int i = 0; i < confettiPositions.length; i++) {
      canvas.drawCircle(
        confettiPositions[i],
        3 + (i % 3) * 2,
        Paint()..color = confettiColors[i % confettiColors.length],
      );
    }

    // Star shapes
    _drawStar(canvas, Offset(w * 0.2, h * 0.35), 8, const Color(0xFFFFD54F));
    _drawStar(canvas, Offset(w * 0.78, h * 0.3), 6, const Color(0xFFFF9F43));
    _drawStar(canvas, Offset(w * 0.85, h * 0.7), 5, const Color(0xFF2DB573));

    // Trophy
    _drawTrophy(canvas, Offset(cx, h * 0.48), w * 0.22);

    // Person
    _drawCelebrationPerson(canvas, Offset(cx - w * 0.18, h * 0.55), w * 0.14);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = -1.5708 + (i * 1.2566);
      final outerX = center.dx + radius * _cos(angle);
      final outerY = center.dy + radius * _sin(angle);
      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      final innerAngle = angle + 0.6283;
      final innerX = center.dx + radius * 0.4 * _cos(innerAngle);
      final innerY = center.dy + radius * 0.4 * _sin(innerAngle);
      path.lineTo(innerX, innerY);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  double _cos(double radians) => cos(radians);
  double _sin(double radians) => sin(radians);

  void _drawTrophy(Canvas canvas, Offset center, double scale) {
    // Cup body
    final cupPath = Path();
    cupPath.moveTo(center.dx - scale * 0.55, center.dy - scale * 0.8);
    cupPath.lineTo(center.dx - scale * 0.45, center.dy + scale * 0.2);
    cupPath.quadraticBezierTo(
      center.dx, center.dy + scale * 0.45,
      center.dx + scale * 0.45, center.dy + scale * 0.2,
    );
    cupPath.lineTo(center.dx + scale * 0.55, center.dy - scale * 0.8);
    cupPath.close();
    canvas.drawPath(cupPath, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawPath(
      cupPath,
      Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Trophy rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - scale * 0.8),
          width: scale * 1.3,
          height: scale * 0.18,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFC107),
    );

    // Handles
    final handlePaint = Paint()
      ..color = const Color(0xFFFFC107)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    // Left handle
    final leftHandle = Path();
    leftHandle.moveTo(center.dx - scale * 0.5, center.dy - scale * 0.5);
    leftHandle.quadraticBezierTo(
      center.dx - scale * 0.9, center.dy - scale * 0.2,
      center.dx - scale * 0.45, center.dy + scale * 0.05,
    );
    canvas.drawPath(leftHandle, handlePaint);
    // Right handle
    final rightHandle = Path();
    rightHandle.moveTo(center.dx + scale * 0.5, center.dy - scale * 0.5);
    rightHandle.quadraticBezierTo(
      center.dx + scale * 0.9, center.dy - scale * 0.2,
      center.dx + scale * 0.45, center.dy + scale * 0.05,
    );
    canvas.drawPath(rightHandle, handlePaint);

    // Star on trophy
    _drawStar(
        canvas,
        Offset(center.dx, center.dy - scale * 0.3),
        scale * 0.2,
        const Color(0xFFF57F17));

    // Base stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + scale * 0.55),
          width: scale * 0.2,
          height: scale * 0.35,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFFC107),
    );

    // Base plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + scale * 0.78),
          width: scale * 0.7,
          height: scale * 0.12,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFC107),
    );
  }

  void _drawCelebrationPerson(Canvas canvas, Offset pos, double scale) {
    final skinColor = const Color(0xFFFFD8B5);
    final shirtColor = const Color(0xFFFF8A50);
    final pantsColor = const Color(0xFF1F2937);

    // Head
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - scale * 1.8),
      scale * 0.35,
      Paint()..color = skinColor,
    );

    // Hair
    canvas.drawCircle(
      Offset(pos.dx, pos.dy - scale * 2.0),
      scale * 0.32,
      Paint()..color = const Color(0xFF2DB573),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy - scale * 1.0),
          width: scale * 0.75,
          height: scale * 1.2,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = shirtColor,
    );

    // Arms raised in celebration
    final armPaint = Paint()
      ..color = skinColor
      ..strokeWidth = scale * 0.14
      ..strokeCap = StrokeCap.round;
    // Left arm up
    canvas.drawLine(
      Offset(pos.dx - scale * 0.38, pos.dy - scale * 1.3),
      Offset(pos.dx - scale * 0.7, pos.dy - scale * 2.0),
      armPaint,
    );
    // Right arm up
    canvas.drawLine(
      Offset(pos.dx + scale * 0.38, pos.dy - scale * 1.3),
      Offset(pos.dx + scale * 0.7, pos.dy - scale * 2.0),
      armPaint,
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx - scale * 0.15, pos.dy + scale * 0.2),
          width: scale * 0.22,
          height: scale * 1.0,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = pantsColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx + scale * 0.15, pos.dy + scale * 0.2),
          width: scale * 0.22,
          height: scale * 1.0,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = pantsColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
