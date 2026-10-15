import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';

/// Picks up where the native splash (Bin Buddy on the theme background)
/// leaves off: Bin Buddy hops twice, popping his lid, then the whole screen
/// fades out to reveal the app underneath.
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
  String _version = '';
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _controller.forward();
    _delayTimer = Timer(_splashDuration, () {
      if (mounted) widget.onInitializationComplete();
    });
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = 'v${packageInfo.version}');
  }

  @override
  void dispose() {
    _controller.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

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

        // Covers the home screen being built underneath and keeps taps
        // from reaching it.
        return AbsorbPointer(
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Material(
              color: palette.ground,
              child: Stack(
                children: [
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
                        ),
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
