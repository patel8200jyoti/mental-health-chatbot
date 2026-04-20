import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));

    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width:  double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [Color(0xFFEEFBF8), Color(0xFFE4F6F2), Color(0xFFF4F8FB)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    // ── Logo + name + tagline ────────────────────────────
                    _buildBrand(),

                    const SizedBox(height: 48),

                    // ── Floating feature cards ───────────────────────────
                    Expanded(child: _buildIllustration()),

                    // ── Buttons ──────────────────────────────────────────
                    _buildButtons(),

                    const SizedBox(height: 16),
                    const Text(
                      'Your journey to wellbeing starts here',
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand block ──────────────────────────────────────────────────────────

  Widget _buildBrand() {
    return Column(children: [
      // Logo — just the spa icon, no white box
      const CircleAvatar(
        backgroundColor: Colors.teal,
        radius:          48,
        child: Icon(Icons.spa, color: Colors.white, size: 52),
      ),

      const SizedBox(height: 22),

      // App name
      RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Mind',
              style: TextStyle(
                fontSize:   34,
                fontWeight: FontWeight.w700,
                color:      Color(0xFF0F2D26),
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: 'Ease',
              style: TextStyle(
                fontSize:   34,
                fontWeight: FontWeight.w300,
                fontStyle:  FontStyle.italic,
                color:      Color(0xFF4FBFA5),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 10),

      const Text(
        'Your pocket companion for mental wellness —\ncalm, guided, always here.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize:  14.5,
          color:     Color(0xFF4B6B62),
          height:    1.55,
        ),
      ),
    ]);
  }

  // ── Floating cards illustration ──────────────────────────────────────────

  Widget _buildIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Card 1 — top left, tilted
        Positioned(
          left: 0, top: 30,
          child: Transform.rotate(
            angle: -0.07,
            child: _FeatureCard(
              emoji: '😌',
              title: 'Feeling Calm',
              sub:   'Just logged · today',
            ),
          ),
        ),
        // Card 2 — centre right
        Positioned(
          right: 0, top: 100,
          child: Transform.rotate(
            angle: 0.05,
            child: _FeatureCard(
              emoji: '🌿',
              title: 'Breathing Exercise',
              sub:   '4-7-8 technique',
              tinted: true,
            ),
          ),
        ),
        // Card 3 — bottom left
        Positioned(
          left: 16, bottom: 30,
          child: Transform.rotate(
            angle: -0.02,
            child: _FeatureCard(
              emoji: '✨',
              title: '7 day streak',
              sub:   'Keep it up!',
            ),
          ),
        ),
      ],
    );
  }

  // ── Buttons ──────────────────────────────────────────────────────────────

  Widget _buildButtons() {
    return Column(children: [
      // Primary — Sign Up
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/signup'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FBFA5),
            foregroundColor: Colors.white,
            padding:         const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: 0,
            shadowColor: Colors.transparent,
          ).copyWith(
            // Subtle gradient via overlayColor trick
            backgroundColor: WidgetStateProperty.all(const Color(0xFF4FBFA5)),
          ),
          child: const Text('Create Account',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  letterSpacing: 0.2)),
        ),
      ),

      const SizedBox(height: 12),

      // Secondary — Sign In
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4FBFA5),
            side:    const BorderSide(color: Color(0xFF4FBFA5), width: 1.8),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:   RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: const Text('Log In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Floating feature card
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String sub;
  final bool   tinted;

  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.sub,
    this.tinted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:        tinted ? const Color(0xFFEEFBF8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize:       MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 2),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ],
      ),
    );
  }
}