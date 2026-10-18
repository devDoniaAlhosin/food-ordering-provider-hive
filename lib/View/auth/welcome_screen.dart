import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/sample_foods.dart';
import '../../theme/app_theme.dart';
import 'auth_tabs_screen.dart';

/// Visual-rich welcome / brand intro before Noon-style auth tabs.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  static const _heroes = [
    (
      image:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1400',
      title: 'Crave-worthy',
      subtitle: 'Burgers, wraps & comfort food',
    ),
    (
      image:
          'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=1400',
      title: 'Wood-fired',
      subtitle: 'Pizza fresh from the oven',
    ),
    (
      image:
          'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=1400',
      title: 'Chef picks',
      subtitle: 'Sushi, pasta & more',
    ),
    (
      image:
          'https://images.unsplash.com/photo-1645112411341-6c4fd023882c?w=1400',
      title: 'Creamy bowls',
      subtitle: 'Pasta made to order',
    ),
  ];

  late final PageController _heroController;
  late final PageController _dishController;
  late final AnimationController _intro;
  late final AnimationController _ctaPulse;
  late final AnimationController _float;

  late final Animation<double> _fadeBrand;
  late final Animation<double> _fadeBody;
  late final Animation<double> _fadeCta;
  late final Animation<Offset> _slideBrand;
  late final Animation<Offset> _slideCta;

  int _heroIndex = 0;
  int _dishIndex = 0;
  Timer? _autoPlay;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _heroController = PageController();
    _dishController = PageController(viewportFraction: 0.46);

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ctaPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _fadeBrand = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _slideBrand = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _fadeBody = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.25, 0.7, curve: Curves.easeOut),
    );
    _fadeCta = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _slideCta = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _intro.forward();
    _startAutoPlay();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_dishController.hasClients) {
        _dishController.jumpToPage(1);
      }
    });
  }

  void _startAutoPlay() {
    _autoPlay?.cancel();
    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_heroController.hasClients) return;
      final next = (_heroIndex + 1) % _heroes.length;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _heroController.dispose();
    _dishController.dispose();
    _intro.dispose();
    _ctaPulse.dispose();
    _float.dispose();
    super.dispose();
  }

  void _openAuth({int tab = 0}) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondary) =>
            AuthTabsScreen(initialIndex: tab),
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final dishes = sampleFoods;
    final floatFoods = sampleFoods.take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed hero gallery
          GestureDetector(
            onVerticalDragUpdate: (d) {
              setState(() {
                _dragOffset =
                    (_dragOffset - d.delta.dy * 0.35).clamp(0.0, 120.0);
              });
            },
            onVerticalDragEnd: (d) {
              final shouldOpen =
                  _dragOffset > 72 || (d.primaryVelocity ?? 0) < -650;
              setState(() => _dragOffset = 0);
              if (shouldOpen) _openAuth(tab: 0);
            },
            child: Transform.translate(
              offset: Offset(0, -_dragOffset * 0.25),
              child: PageView.builder(
                controller: _heroController,
                itemCount: _heroes.length,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _heroIndex = i);
                  _startAutoPlay();
                },
                itemBuilder: (context, index) {
                  final hero = _heroes[index];
                  return _HeroSlide(
                    imageUrl: hero.image,
                    active: index == _heroIndex,
                  );
                },
              ),
            ),
          ),

          // Floating circular food visuals
          FadeTransition(
            opacity: _fadeBody,
            child: AnimatedBuilder(
              animation: _float,
              builder: (context, _) {
                final t = _float.value;
                return Stack(
                  children: [
                    _FloatingFoodOrb(
                      imageUrl: floatFoods[0].imageUrl,
                      size: 78,
                      left: size.width * 0.72,
                      top: size.height * 0.14 + math.sin(t * math.pi) * 10,
                      angle: -0.12 + t * 0.06,
                    ),
                    _FloatingFoodOrb(
                      imageUrl: floatFoods[1].imageUrl,
                      size: 58,
                      left: size.width * 0.08,
                      top: size.height * 0.22 + math.cos(t * math.pi) * 8,
                      angle: 0.1 - t * 0.05,
                    ),
                    _FloatingFoodOrb(
                      imageUrl: floatFoods[2].imageUrl,
                      size: 64,
                      left: size.width * 0.78,
                      top: size.height * 0.32 + math.sin(t * math.pi + 1) * 12,
                      angle: 0.08,
                    ),
                    _FloatingFoodOrb(
                      imageUrl: floatFoods[3].imageUrl,
                      size: 48,
                      left: size.width * 0.04,
                      top: size.height * 0.38 + math.cos(t * math.pi + 0.5) * 9,
                      angle: -0.15,
                    ),
                    // Soft ring accent behind collage
                    Positioned(
                      right: 18,
                      top: size.height * 0.11,
                      child: Transform.rotate(
                        angle: t * 0.2,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFCC80)
                                  .withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Photo collage cluster (top-right)
          FadeTransition(
            opacity: _fadeBrand,
            child: Align(
              alignment: const Alignment(0.92, -0.62),
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, math.sin(_float.value * math.pi) * 6),
                    child: child,
                  );
                },
                child: _PhotoCollage(
                  images: [
                    floatFoods[0].imageUrl,
                    floatFoods[4].imageUrl,
                    floatFoods[2].imageUrl,
                  ],
                ),
              ),
            ),
          ),

          // Depth scrims
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.94),
                ],
                stops: const [0, 0.26, 0.58, 1],
              ),
            ),
          ),

          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.75, -0.5),
                  radius: 1.05,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeTransition(
                    opacity: _fadeBrand,
                    child: Row(
                      children: [
                        _BrandMark(pulse: _ctaPulse),
                        const SizedBox(width: 10),
                        Text(
                          'Food Cart',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _openAuth(tab: 0),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  SlideTransition(
                    position: _slideBrand,
                    child: FadeTransition(
                      opacity: _fadeBrand,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order the\ngood stuff.',
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.6,
                              height: 0.98,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            child: Column(
                              key: ValueKey(_heroIndex),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _heroes[_heroIndex].title,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: const Color(0xFFFFCC80),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _heroes[_heroIndex].subtitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _HeroDots(
                            count: _heroes.length,
                            index: _heroIndex,
                            onTap: (i) {
                              _heroController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          // Category visual chips with food thumbs
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: math.min(5, dishes.length),
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final food = dishes[i];
                                return _CategoryChip(
                                  label: food.category,
                                  imageUrl: food.imageUrl,
                                  selected: i == _heroIndex % 5,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _heroController.animateToPage(
                                      i % _heroes.length,
                                      duration:
                                          const Duration(milliseconds: 420),
                                      curve: Curves.easeOutCubic,
                                    );
                                    _dishController.animateToPage(
                                      i,
                                      duration:
                                          const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.02),

                  // Visual dish strip
                  FadeTransition(
                    opacity: _fadeBody,
                    child: SizedBox(
                      height: 168,
                      child: PageView.builder(
                        controller: _dishController,
                        itemCount: dishes.length,
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _dishIndex = i);
                        },
                        itemBuilder: (context, index) {
                          final food = dishes[index];
                          return AnimatedBuilder(
                            animation: _dishController,
                            builder: (context, child) {
                              double scale = 0.88;
                              if (_dishController.position.haveDimensions) {
                                final page = _dishController.page ??
                                    _dishIndex.toDouble();
                                scale = (1 - (page - index).abs() * 0.12)
                                    .clamp(0.84, 1.0);
                              } else if (index == _dishIndex) {
                                scale = 1;
                              }
                              return Transform.scale(
                                scale: scale,
                                child: child,
                              );
                            },
                            child: _DishTile(
                              name: food.name,
                              imageUrl: food.imageUrl,
                              price: food.price,
                              category: food.category,
                              selected: index == _dishIndex,
                              onTap: () {
                                _dishController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                );
                                HapticFeedback.lightImpact();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const Spacer(),

                  SlideTransition(
                    position: _slideCta,
                    child: FadeTransition(
                      opacity: _fadeCta,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Mini visual preview row in CTA
                                SizedBox(
                                  height: 36,
                                  child: Row(
                                    children: [
                                      ...List.generate(4, (i) {
                                        return Transform.translate(
                                          offset: Offset(i * -8.0, 0),
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: Image.network(
                                                dishes[i].imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    ColoredBox(
                                                  color: theme
                                                      .colorScheme.primary,
                                                  child: const Icon(
                                                    Icons.fastfood,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${dishes.length} dishes ready',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                AnimatedBuilder(
                                  animation: _ctaPulse,
                                  builder: (context, child) {
                                    final glow =
                                        0.18 + (_ctaPulse.value * 0.16);
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: glow),
                                            blurRadius: 22,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: child,
                                    );
                                  },
                                  child: FilledButton(
                                    onPressed: () => _openAuth(tab: 1),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text('Create account'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => _openAuth(tab: 0),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.35),
                                    ),
                                    minimumSize: const Size.fromHeight(50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Sign in'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingFoodOrb extends StatelessWidget {
  const _FloatingFoodOrb({
    required this.imageUrl,
    required this.size,
    required this.left,
    required this.top,
    this.angle = 0,
  });

  final String imageUrl;
  final double size;
  final double left;
  final double top;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: AppTheme.ink,
                child: Icon(
                  Icons.restaurant,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoCollage extends StatelessWidget {
  const _PhotoCollage({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 8,
            child: _CollageShot(
              imageUrl: images[0],
              size: 72,
              angle: 0.12,
            ),
          ),
          Positioned(
            left: 0,
            top: 28,
            child: _CollageShot(
              imageUrl: images[1],
              size: 58,
              angle: -0.16,
            ),
          ),
          Positioned(
            right: 28,
            bottom: 0,
            child: _CollageShot(
              imageUrl: images[2],
              size: 48,
              angle: 0.08,
              ring: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollageShot extends StatelessWidget {
  const _CollageShot({
    required this.imageUrl,
    required this.size,
    required this.angle,
    this.ring = false,
  });

  final String imageUrl;
  final double size;
  final double angle;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ring
                ? const Color(0xFFFFCC80)
                : Colors.white.withValues(alpha: 0.7),
            width: ring ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: AppTheme.ink,
            child: Icon(Icons.fastfood, color: Colors.white38),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFCC80)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Image.network(
                imageUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppTheme.ink,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: Icon(
                      Icons.fastfood,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.pulse});

  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final s = 1 + (pulse.value * 0.04);
        return Transform.scale(scale: s, child: child);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.restaurant_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  const _HeroSlide({
    required this.imageUrl,
    required this.active,
  });

  final String imageUrl;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: active ? 1.05 : 1.0, end: active ? 1.0 : 1.05),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) => Container(
          color: AppTheme.ink,
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant,
            color: Colors.white24,
            size: 72,
          ),
        ),
      ),
    );
  }
}

class _HeroDots extends StatelessWidget {
  const _HeroDots({
    required this.count,
    required this.index,
    required this.onTap,
  });

  final int count;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (i) {
        final selected = i == index;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(right: 8),
            width: selected ? 28 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFFFCC80)
                  : Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final double price;
  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? const Color(0xFFFFCC80)
                  : Colors.white.withValues(alpha: 0.2),
              width: selected ? 2.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.4 : 0.22),
                blurRadius: selected ? 20 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: AppTheme.ink,
                  child: Icon(
                    Icons.fastfood,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    category,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFFFCC80),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
