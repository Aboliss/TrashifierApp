import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/widgets/bin_buddy.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _splashDuration = Duration(milliseconds: 1200);

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _version = '';
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: _splashDuration,
      vsync: this,
    );

    _slideAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.decelerate)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.0),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 40.0,
      ),
    ]).animate(_animationController);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 60.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20.0,
      ),
    ]).animate(_animationController);

    _loadPackageInfo();
    _startAnimations();
  }

  Future<void> _loadPackageInfo() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = 'v${packageInfo.version}';
    });
  }

  void _startAnimations() {
    _animationController.forward();

    _delayTimer = Timer(_splashDuration, () {
      if (mounted) {
        widget.onInitializationComplete();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: palette.ground,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(_slideAnimation.value * screenWidth, 0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        const BinBuddy.appIcon(size: 120),
                        Text(
                          'trashifier',
                          style: AppFonts.headline(36, palette.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Static version text at the bottom
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _fadeAnimation.value,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
