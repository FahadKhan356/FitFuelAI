import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
// Subscription screen
const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleSoft = Color(0xFFEDEBFB);
const _textPrimary = Color(0xFF1E1D2A);
const _textSecondary = Color(0xFF6F6C7B);
const _border = Color(0xFFE7E3EF);
const _borderStrong = Color(0xFF5B4EE8);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _staggered({
    required Widget child,
    required double start,
    required double end,
    double offsetY = 24,
  }) {
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Transform.translate(
          offset: Offset(0, offsetY * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _staggered(
                      start: 0.0,
                      end: 0.18,
                      offsetY: 12,
                      child: Row(
                        children: [
                          _IconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Upgrade to Pro',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _staggered(
                      start: 0.1,
                      end: 0.28,
                      offsetY: 18,
                      child: Column(
                        children: [
                          Center(
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: const BoxDecoration(
                                color: _purple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium_outlined,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Master Your Nutrition',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                  height: 1.05,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Unlock the full power of AI-driven\nwellness and reach your goals 2x faster.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontSize: 16,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: _textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _staggered(
                      start: 0.22,
                      end: 0.36,
                      offsetY: 20,
                      child: Row(
                        children: [
                          Text(
                            'Premium Benefits',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: _purpleSoft,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFD7D0F7)),
                            ),
                            child: Text(
                              'ALL FEATURES UNLOCKED',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: _purple,
                                    letterSpacing: 0.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _staggered(
                      start: 0.30,
                      end: 0.46,
                      offsetY: 24,
                      child: const Row(
                        children: [
                          Expanded(
                            child: _BenefitCard(
                              icon: Icons.bolt_rounded,
                              title: 'Infinite Scanning',
                              subtitle: 'No daily limits on food lookups',
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _BenefitCard(
                              icon: Icons.auto_awesome_rounded,
                              title: 'Pro AI Coach',
                              subtitle: '24/7 dedicated nutrition advice',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      start: 0.34,
                      end: 0.50,
                      offsetY: 24,
                      child: const Row(
                        children: [
                          Expanded(
                            child: _BenefitCard(
                              icon: Icons.bar_chart_rounded,
                              title: 'Advanced Stats',
                              subtitle: 'Detailed micro & macro tracking',
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _BenefitCard(
                              icon: Icons.smartphone_outlined,
                              title: 'Offline Mode',
                              subtitle: 'Scan meals without an internet connection',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _staggered(
                      start: 0.42,
                      end: 0.56,
                      offsetY: 18,
                      child: Text(
                        'Choose Your Plan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      start: 0.46,
                      end: 0.62,
                      offsetY: 20,
                      child: const _PlanCard(
                        title: 'Monthly Access',
                        price: r'$9.99',
                        period: '/mo',
                        selected: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      start: 0.50,
                      end: 0.66,
                      offsetY: 20,
                      child: const _PlanCard(
                        title: 'Annual Premium',
                        price: r'$4.99',
                        period: '/mo',
                        selected: true,
                        tag: 'BEST VALUE',
                        subline: 'SAVE 50%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      start: 0.54,
                      end: 0.70,
                      offsetY: 20,
                      child: const _PlanCard(
                        title: 'Lifetime Legend',
                        price: r'$99.99',
                        period: 'once',
                        selected: false,
                        subline: 'ONE TIME',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _staggered(
                      start: 0.62,
                      end: 0.76,
                      offsetY: 22,
                      child: const _SocialProofCard(),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: _staggered(
                start: 0.72,
                end: 0.92,
                offsetY: 20,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(58),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Start 7-Day Free Trial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            icon,
            size: 20,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 155,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _purpleSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: _purple,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _textSecondary,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    this.tag,
    this.subline,
  });

  final String title;
  final String price;
  final String period;
  final bool selected;
  final String? tag;
  final String? subline;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? _borderStrong : _border;
    final backgroundColor = selected ? const Color(0xFFFDFCFF) : _surface;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: selected ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: selected
                ? const Color(0xFF5B4EE8).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _purple : Colors.transparent,
                    border: Border.all(
                      color: selected ? _purple : const Color(0xFFC8C4D6),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      if (subline != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subline!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: period == 'once' ? ' once' : period,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (tag != null)
            Positioned(
              right: 0,
              top: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Text(
                  tag!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SocialProofCard extends StatelessWidget {
  const _SocialProofCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AvatarChip(
                color: const Color(0xFFF4D0C8),
                initials: 'A',
              ),
              const SizedBox(width: 6),
              _AvatarChip(
                color: const Color(0xFFD4C6FF),
                initials: 'M',
              ),
              const SizedBox(width: 6),
              _AvatarChip(
                color: const Color(0xFFC7E6F3),
                initials: 'K',
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Joined by 50k+ healthy users',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => const Padding(
                    padding: EdgeInsets.only(left: 1),
                    child: Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFD8D8DF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, size: 18, color: _purple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Secure checkout. Cancel anytime in your App Store settings. 7-day free trial applies to the Yearly plan.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: _textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({
    required this.color,
    required this.initials,
  });

  final Color color;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.6),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _textPrimary,
        ),
      ),
    );
  }
}
