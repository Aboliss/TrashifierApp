import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';
import 'package:trashifier_app/widgets/season_decor.dart';

/// Picks up where the native splash (Bin Buddy on the theme background)
/// leaves off: Bin Buddy hops twice, popping his lid, then the whole screen
/// fades out to reveal the app underneath.
///
/// In season he changes into his costume at the top of the first hop, with
/// a sparkle, while the background warms up to the seasonal color. (The
/// native splash is built into the app and can't know the season.)
class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  /// Matches the mascot's size on the native splash so the hand-over is
  /// seamless.
  static const double buddySize = 176;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _splashDuration = Duration(milliseconds: 1600);

  /// Hops happen in this part of the animation, then it fades out.
  static const double _hopsEnd = 0.8;
  static const int _hops = 2;

  late final AnimationController _controller = AnimationController(
    duration: _splashDuration,
    vsync: this,
  );

  /// If the animation hasn't finished this long after the first frame, close
  /// anyway: the splash blocks the app underneath.
  static const Duration _maxDuration = Duration(seconds: 4);

  /// Last resort when no frame is drawn at all. Counted from start-up, so it
  /// must allow for slow devices, where the first frame can take seconds.
  static const Duration _noFrameTimeout = Duration(seconds: 10);

  String _version = '';
  Timer? _fallback;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _fallback = Timer(_noFrameTimeout, _finish);
    // Start once the first frames are on screen: the app's start-up work makes
    // them slow, and an animation started earlier would already be over by
    // the time it is drawn. Close when it has played.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fallback?.cancel();
      _fallback = Timer(_maxDuration, _finish);
      // Ask for the frame to wait on; otherwise it only comes if something
      // else happens to schedule one.
      SchedulerBinding.instance.scheduleFrame();
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
      _controller.forward().whenCompleteOrCancel(_finish);
    });
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _fallback?.cancel();
    widget.onInitializationComplete();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = 'v${packageInfo.version}');
    } catch (e) {
      // The version line is decoration; the splash works without it.
      debugPrint('Failed to read app version: $e');
    }
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final season = context.season;
    final costume = context.buddyCostume;
    // The native splash's background, which the seasonal one fades in from.
    final nativeGround = AppPalette.of(
      Season.none,
      Theme.of(context).brightness,
    ).ground;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Each hop: rise and fall on a sine arc; the lid trails the body
        // and lifts off at the top.
        var hop = 0.0;
        var lid = 0.0;
        var squash = 1.0;
        if (t < _hopsEnd) {
          final phase = (t / _hopsEnd) * _hops % 1;
          hop = math.sin(phase * math.pi);
          lid = math.max(0, math.sin((phase - 0.1) * math.pi));
          // Squash briefly on landing and take-off.
          if (phase < 0.08 || phase > 0.92) squash = 0.94;
        }
        final opacity = t < 0.85 ? 1.0 : 1 - (t - 0.85) / 0.15;

        // The costume change happens at the top of the first hop.
        const swapAt = _hopsEnd / _hops / 2;
        final changed = t >= swapAt;
        final sparkle = season == Season.none
            ? 0.0
            : math.max(0.0, 1 - (t - swapAt).abs() / 0.08);
        final ground = Color.lerp(
          nativeGround,
          palette.ground,
          Curves.easeOut.transform((t / swapAt).clamp(0.0, 1.0)),
        )!;

        // Covers the home screen being built underneath and keeps taps
        // from reaching it.
        return AbsorbPointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Material(
              color: ground,
              child: Stack(
                children: [
                  if (season == Season.christmas) ...[
                    const Positioned.fill(child: SnowLayer()),
                    Positioned(
                      top: MediaQuery.paddingOf(context).top,
                      left: 0,
                      right: 0,
                      child: const LightsString(),
                    ),
                  ],
                  if (season == Season.halloween) ..._spooks(context),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -28 * hop),
                      child: Transform.scale(
                        scaleX: 2 - squash,
                        scaleY: squash,
                        alignment: Alignment.bottomCenter,
                        child: BinBuddy(
                          size: SplashScreen.buddySize,
                          lidColor: palette.ink,
                          onDark: context.isDark,
                          lidLift: 12 * lid,
                          costume: changed ? costume : BuddyCostume.normal,
                        ),
                      ),
                    ),
                  ),
                  if (sparkle > 0)
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, -28 * hop),
                        child: CustomPaint(
                          size: const Size.square(SplashScreen.buddySize * 1.4),
                          painter: _SparklePainter(sparkle),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        _version,
                        style: TextStyle(
                          fontSize: 15,
                          color: palette.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A ghost floating beside Bin Buddy and a spider dropping in from the top.
List<Widget> _spooks(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return [
    Positioned(
      left: size.width * 0.16,
      top: size.height * 0.34,
      child: FloatingGhost(width: 38, outlined: !context.isDark),
    ),
    Positioned(
      right: size.width * 0.2,
      top: 0,
      child: HangingSpider(
        color: SeasonDecorColors.spider(onDark: context.isDark),
        drop: size.height * 0.33,
      ),
    ),
  ];
}

/// Four gold twinkles around Bin Buddy as he changes into his costume.
class _SparklePainter extends CustomPainter {
  final double strength;

  _SparklePainter(this.strength);

  static const List<(double, double, double)> _stars = [
    (0.12, 0.30, 1.0),
    (0.86, 0.22, 0.8),
    (0.90, 0.70, 0.8),
    (0.10, 0.76, 0.7),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF2C14E).withValues(alpha: strength);
    for (final (fx, fy, scale) in _stars) {
      final c = Offset(fx * size.width, fy * size.height);
      final r = 14 * scale * (0.6 + 0.4 * strength);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.strength != strength;
}
