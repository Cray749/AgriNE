/// AgriSutra NE — Screen 2: Landing Screen
/// ==========================================
/// First screen a new farmer sees. Goal: build trust quickly and
/// lead them to login. Scrollable. Five sections:
///   A. Hero (gradient, headline, CTA)
///   B. How It Works (3 step cards)
///   C. Features (2×2 grid)
///   D. Trust badges
///   E. Footer
///
/// All elements fade + slide up when they scroll into view,
/// implemented via _AnimatedSection wrapper (no extra packages needed).

import 'package:flutter/material.dart';
import '../core/theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final Animation<double>   _heroFade;
  late final Animation<Offset>   _heroSlide;

  @override
  void initState() {
    super.initState();
    _heroCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _heroFade  = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic));
    _heroCtrl.forward();
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      // No AppBar — hero section bleeds to the top edge (immersive)
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            _buildHowItWorksSection(),
            _buildFeaturesSection(),
            _buildTrustSection(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION A — HERO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.light
              ? [kGreenPrimary, kLightBgPrimary]
              : [kBgDark, kBgCard],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: FadeTransition(
            opacity: _heroFade,
            child: SlideTransition(
              position: _heroSlide,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── STCR badge chip ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      border: Border.all(color: kGreenAccent, width: 1.2),
                      borderRadius: BorderRadius.circular(kRadiusChip),
                      color: kGreenAccent.withOpacity(0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔬', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 6),
                        Text(
                          'STCR Certified Method',
                          style: kStyleLabel.copyWith(color: kGreenAccent),
                        ),
                      ],
                    ),
                  ),

                  kGapL,

                  // ── Main headline ──────────────────────────────────────
                  Text(
                    'Smart Fertilizer\nRecommendations\nfor NE India',
                    style: kStyleHeadingXL.copyWith(height: 1.2),
                  ),

                  kGapM,

                  // ── Sub-headline ──────────────────────────────────────
                  Text(
                    'Tell us your soil. We tell you exactly what to apply.',
                    style: kStyleBodyL.copyWith(color: kTextSecondary),
                  ),

                  kGapL,

                  // ── Hero illustration (placeholder until hero_farmer.png added)
                  // ── TODO: Replace Container with:
                  //    Image.asset('assets/images/hero_farmer.png',
                  //      width: double.infinity, height: 200, fit: BoxFit.cover)
                  _HeroIllustration(),

                  kGapL,

                  // ── Primary CTA button ────────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreenPrimary,
                        foregroundColor: kTextHighlight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusButton),
                        ),
                        textStyle: kStyleHeadingM,
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Get Free Recommendation'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),

                  kGapM,

                  // ── Secondary login link ──────────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        'Already registered? Log In',
                        style: kStyleBodyM.copyWith(
                          color: kGreenAccent,
                          decoration: TextDecoration.underline,
                          decorationColor: kGreenAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION B — HOW IT WORKS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHowItWorksSection() {
    final steps = [
      _StepData(
        number: '1',
        emoji: '🌽',
        title: 'Enter Your Crop & Soil',
        body: 'Select Maize or Kholar. Tell us if your soil is Low, Medium or High in nutrients.',
      ),
      _StepData(
        number: '2',
        emoji: '🔬',
        title: 'STCR Engine Calculates',
        body: 'Our engine uses field-tested STCR formulas developed for Kiphire region soils.',
      ),
      _StepData(
        number: '3',
        emoji: '🧪',
        title: 'Get Exact Amounts',
        body: 'You receive exact kg of Urea, SSP and MOP for your field size — ready to buy.',
      ),
    ];

    return _AnimatedSection(
      child: Container(
        color: ctxCard(context),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          children: [
            // Section header
            Row(
              children: [
                Container(width: 4, height: 28,
                    decoration: BoxDecoration(color: kGreenAccent, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Text('How It Works', style: kStyleHeadingL),
              ],
            ),

            kGapL,

            // Step cards
            ...steps.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: e.key < steps.length - 1 ? 16 : 0),
              child: _StepCard(data: e.value),
            )),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION C — FEATURES  (2 × 2 grid)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFeaturesSection() {
    final features = [
      _FeatureData('🌏', 'Built for NE India',
          'Formulas tuned for Kiphire, Assam & Nagaland agro-climate'),
      _FeatureData('📐', 'Science-Backed',
          'Uses STCR methodology verified by agricultural institutes'),
      _FeatureData('📱', 'Works Offline*',
          'Results shown instantly. No internet needed after first load'),
      _FeatureData('🗣️', 'Simple to Use',
          'No jargon. Plain language. Farmer-friendly design'),
    ];

    return _AnimatedSection(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 28,
                    decoration: BoxDecoration(color: kColorP, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Text('Why AgriSutra NE?', style: kStyleHeadingL),
              ],
            ),

            kGapL,

            // 2×2 grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.9,
              children: features.map((f) => _FeatureCard(data: f)).toList(),
            ),

            kGapM,

            // Asterisk footnote
            Text(
              '* Offline mode available in Phase 2',
              style: kStyleLabel.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION D — TRUST BADGES
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTrustSection() {
    final badges = [
      ('✅', 'Validated\nfor Kiphire'),
      ('🔬', 'STCR\nResearch'),
      ('👨‍🌾', 'Farmer\nTested'),
    ];

    return _AnimatedSection(
      child: Container(
        color: ctxCard(context),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Text(
              'Trusted by Farmers Across Northeast India',
              style: kStyleHeadingM,
              textAlign: TextAlign.center,
            ),
            kGapL,
            Row(
              children: badges.map((b) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  decoration: ctxCardDecoration(context, borderColor: kGreenPrimary.withOpacity(0.3)),
                  child: Column(
                    children: [
                      Text(b.$1, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 8),
                      Text(
                        b.$2,
                        style: kStyleLabel.copyWith(color: ctxTextPrimary(context)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION E — FOOTER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFooter() {
    return _AnimatedSection(
      child: Container(
        color: Theme.of(context).brightness == Brightness.light
            ? kLightBgSecondary
            : const Color(0xFF0A0E0C),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Footer links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FooterLink('About Us'),
                _FooterDivider(),
                _FooterLink('Privacy Policy'),
                _FooterDivider(),
                _FooterLink('Contact'),
              ],
            ),

            kGapM,

            // Copyright
            Text(
              '© 2024 AgriSutra NE',
              style: kStyleLabel,
              textAlign: TextAlign.center,
            ),

            kGapS,

            // STCR attribution
            Text(
              'Fertilizer equations based on STCR research.\nDeveloped for Northeast India agro-climate.',
              style: kStyleLabel.copyWith(
                color: kTextSecondary.withOpacity(0.55),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  HERO ILLUSTRATION  (replaces hero_farmer.png until asset is added)
// ════════════════════════════════════════════════════════════════════════════

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadiusCard),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kGreenPrimary.withOpacity(0.20),
            ctxCard(context),
          ],
        ),
        border: Border.all(color: ctxCardBorder(context)),
      ),
      child: Stack(
        children: [
          // Background pattern dots
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),
          // Centre illustration
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🌾', style: TextStyle(fontSize: 56)),
                SizedBox(height: 10),
                Text(
                  'Northeast India\nFertilizer Guide',
                  style: TextStyle(
                    color: kGreenAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // TODO: Replace above with:
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(kRadiusCard),
          //   child: Image.asset('assets/images/hero_farmer.png',
          //     width: double.infinity, height: 200, fit: BoxFit.cover),
          // )
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kGreenAccent.withOpacity(0.07)
      ..strokeWidth = 1;
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}


// ════════════════════════════════════════════════════════════════════════════
//  SUB-WIDGETS
// ════════════════════════════════════════════════════════════════════════════

/// Data container for a How-It-Works step
class _StepData {
  final String number, emoji, title, body;
  const _StepData({required this.number, required this.emoji, required this.title, required this.body});
}

/// One step card — horizontal layout with numbered circle + content
class _StepCard extends StatelessWidget {
  final _StepData data;
  const _StepCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingCard,
      decoration: ctxCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Numbered circle
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kGreenPrimary,
            ),
            child: Center(
              child: Text(
                data.number,
                style: kStyleBodyL.copyWith(
                  color: kTextHighlight,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          kGapHorizontalM,
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(data.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(data.title, style: kStyleHeadingM),
                    ),
                  ],
                ),
                kGapS,
                Text(data.body, style: kStyleBodyM),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Data container for a feature card
class _FeatureData {
  final String emoji, title, body;
  const _FeatureData(this.emoji, this.title, this.body);
}

/// 2×2 grid feature card
class _FeatureCard extends StatelessWidget {
  final _FeatureData data;
  const _FeatureCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ctxCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.emoji, style: const TextStyle(fontSize: 28)),
          kGapS,
          Text(
            data.title,
            style: kStyleBodyL.copyWith(
              fontWeight: FontWeight.w600,
              color: ctxHeading(context),
            ),
          ),
          kGapXS,
          Expanded(
            child: Text(
              data.body,
              style: kStyleBodyM,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Footer link text button
class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: kStyleLabel.copyWith(color: kTextSecondary),
      ),
    );
  }
}

/// Vertical divider between footer links
class _FooterDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text('·', style: kStyleLabel.copyWith(color: kTextSecondary)),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  _AnimatedSection  —  fade + slide-up when widget first becomes visible
//  Used to give each landing page section a clean entrance as user scrolls.
// ════════════════════════════════════════════════════════════════════════════

class _AnimatedSection extends StatefulWidget {
  final Widget child;
  const _AnimatedSection({required this.child});

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.09), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Small delay so sections don't all animate simultaneously on first load
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
