import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/services/season_service.dart';

/// Colors of the seasonal decorations that aren't part of the palette.
class SeasonDecorColors {
  static const Color ghost = Color(0xFFFBF8FD);

  /// Thin outline so the white ghost stands out on light surfaces.
  static const Color ghostOutline = Color(0xFFCDB8DB);
  static const Color ghostFace = Color(0xFF2B1838);

  /// Spiders on light surfaces, and on dark ones (dark mode, hero card).
  static const Color spiderOnLight = Color(0xFF2B1838);
  static const Color spiderOnDark = Color(0xFFB6A9C2);

  static Color spider({required bool onDark}) =>
      onDark ? spiderOnDark : spiderOnLight;
}

bool _animationsOff(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

const String _pumpkinSvg = '''
<svg viewBox="0 0 32 30" xmlns="http://www.w3.org/2000/svg">
<ellipse cx="16" cy="18" rx="14" ry="11" fill="#F2852B"/>
<path d="M10 8Q6 18 10 28M16 7V29M22 8Q26 18 22 28" fill="none" stroke="#D0661A" stroke-width="1.6"/>
<path d="M16 8Q15 3 19 1" fill="none" stroke="#4E6B2A" stroke-width="2.5" stroke-linecap="round"/>
</svg>''';

/// A Halloween ghost, spider or pumpkin on [anchor], when the session's
/// random roll put one there; nothing outside Halloween.
class HalloweenDecor extends StatelessWidget {
  final DecorAnchor anchor;

  /// Light spiders for dark surfaces such as the hero card.
  final bool onDark;

  /// How far a spider hangs down on its thread.
  final double spiderDrop;

  const HalloweenDecor(
    this.anchor, {
    super.key,
    this.onDark = false,
    this.spiderDrop = 16,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SeasonService?>();
    if (service == null || service.season != Season.halloween) {
      return const SizedBox.shrink();
    }
    switch (service.decor[anchor]) {
      case DecorKind.ghost:
        return FloatingGhost(outlined: !(onDark || context.isDark));
      case DecorKind.spider:
        return HangingSpider(
          color: SeasonDecorColors.spider(onDark: onDark || context.isDark),
          drop: spiderDrop,
        );
      case DecorKind.pumpkin:
        return ExcludeSemantics(
          child: SvgPicture.string(_pumpkinSvg, width: 26, height: 24),
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

/// Runs a slow back-and-forth animation for a decoration, unless the phone
/// asks for no animations.
mixin _GentleLoop<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  late final AnimationController loop = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 2200 + Random().nextInt(1400)),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationsOff(context)) {
      loop.stop();
    } else if (!loop.isAnimating) {
      loop.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    loop.dispose();
    super.dispose();
  }

  double get eased => Curves.easeInOut.transform(loop.value);
}

/// A small sheet ghost that floats up and down, swaying a little.
class FloatingGhost extends StatefulWidget {
  final double width;

  /// Adds a thin outline, for light backgrounds.
  final bool outlined;

  const FloatingGhost({super.key, this.width = 24, this.outlined = true});

  @override
  State<FloatingGhost> createState() => _FloatingGhostState();
}

class _FloatingGhostState extends State<FloatingGhost>
    with SingleTickerProviderStateMixin, _GentleLoop {
  static String _svg(bool outlined) {
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final stroke = outlined
        ? 'stroke="${hex(SeasonDecorColors.ghostOutline)}" stroke-width="1.2"'
        : '';
    final face = hex(SeasonDecorColors.ghostFace);
    return '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
        '<path d="M5 22V11a7 7 0 0 1 14 0v11l-2.33-1.8-2.34 1.8-2.33-1.8-2.33 1.8-2.34-1.8Z" '
        'fill="${hex(SeasonDecorColors.ghost)}" $stroke stroke-linejoin="round"/>'
        '<ellipse cx="9.6" cy="11" rx="1.2" ry="1.6" fill="$face"/>'
        '<ellipse cx="14.4" cy="11" rx="1.2" ry="1.6" fill="$face"/>'
        '<circle cx="12" cy="15.2" r="1.1" fill="$face"/>'
        '</svg>';
  }

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.string(
      _svg(widget.outlined),
      width: widget.width,
      height: widget.width,
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: loop,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -4 * eased),
          child: Transform.rotate(angle: 0.12 * (eased - 0.5), child: child),
        ),
        child: svg,
      ),
    );
  }
}

/// A little round spider hanging on its thread, bouncing gently.
class HangingSpider extends StatefulWidget {
  final Color color;

  /// Thread length at rest, from the top of the widget to the spider.
  final double drop;

  const HangingSpider({super.key, required this.color, this.drop = 16});

  @override
  State<HangingSpider> createState() => _HangingSpiderState();
}

class _HangingSpiderState extends State<HangingSpider>
    with SingleTickerProviderStateMixin, _GentleLoop {
  static const double _bounce = 5;
  static const double _width = 22;
  static const double _bodyHeight = 14;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _width,
        height: widget.drop + _bounce + _bodyHeight,
        child: CustomPaint(
          painter: _SpiderPainter(loop, widget.color, widget.drop),
        ),
      ),
    );
  }
}

class _SpiderPainter extends CustomPainter {
  final Animation<double> loop;
  final Color color;
  final double drop;

  _SpiderPainter(this.loop, this.color, this.drop) : super(repaint: loop);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final y =
        drop +
        _HangingSpiderState._bounce * Curves.easeInOut.transform(loop.value);
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Thread
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, y),
      Paint()
        ..color = color.withValues(alpha: 0.6)
        ..strokeWidth = 1,
    );
    // Four legs a side
    final body = Offset(cx, y + 6);
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 4; i++) {
        final start = body.translate(side * 3, -2 + i * 1.6);
        final knee = start.translate(side * 4, -3 + i * 1.4);
        final foot = knee.translate(side * 2.5, 3 + i * 0.6);
        canvas.drawPath(
          Path()
            ..moveTo(start.dx, start.dy)
            ..lineTo(knee.dx, knee.dy)
            ..lineTo(foot.dx, foot.dy),
          ink,
        );
      }
    }
    canvas.drawCircle(body, 4.6, Paint()..color = color);
    // Eyes
    final eye = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(body.translate(-1.6, 0.6), 1.1, eye);
    canvas.drawCircle(body.translate(1.6, 0.6), 1.1, eye);
  }

  @override
  bool shouldRepaint(_SpiderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.drop != drop;
}

/// Snow falling behind the content during Christmas.
class SnowLayer extends StatefulWidget {
  final int flakeCount;

  const SnowLayer({super.key, this.flakeCount = 26});

  @override
  State<SnowLayer> createState() => _SnowLayerState();
}

class _Flake {
  final double x;
  final double phase;
  final double radius;
  final double speed;
  final double sway;
  final double opacity;

  _Flake(Random random)
    : x = random.nextDouble(),
      phase = random.nextDouble(),
      radius = 1 + random.nextDouble() * 1.6,
      speed = 0.6 + random.nextDouble() * 0.8,
      sway = 4 + random.nextDouble() * 8,
      opacity = 0.5 + random.nextDouble() * 0.4;
}

class _SnowLayerState extends State<SnowLayer>
    with SingleTickerProviderStateMixin {
  // One slow loop; each flake falls at its own speed within it.
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final List<_Flake> _flakes = List.generate(
    widget.flakeCount,
    (_) => _Flake(Random()),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationsOff(context)) {
      _time.stop();
    } else if (!_time.isAnimating) {
      _time.repeat();
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFFB9CAD6);
    return IgnorePointer(
      child: CustomPaint(
        painter: _SnowPainter(_flakes, _time, color),
        size: Size.infinite,
      ),
    );
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Flake> flakes;
  final Animation<double> time;
  final Color color;

  _SnowPainter(this.flakes, this.time, this.color) : super(repaint: time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final travel = size.height + 20;
    for (final flake in flakes) {
      // Whole number of falls per loop so the animation repeats seamlessly.
      final falls = (flake.speed * 3).roundToDouble().clamp(1, 4);
      final progress = (flake.phase + time.value * falls) % 1;
      final y = progress * travel - 10;
      final x =
          flake.x * size.width +
          sin((progress * 2 + flake.phase) * pi * 2) * flake.sway;
      paint.color = color.withValues(alpha: flake.opacity);
      canvas.drawCircle(Offset(x, y), flake.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.flakes != flakes;
}

/// One string of softly blinking Christmas lights along the top.
class LightsString extends StatefulWidget {
  static const double height = 30;

  const LightsString({super.key});

  @override
  State<LightsString> createState() => _LightsStringState();
}

class _LightsStringState extends State<LightsString>
    with SingleTickerProviderStateMixin {
  late final AnimationController _time = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_animationsOff(context)) {
      _time.stop();
      _time.value = 0;
    } else if (!_time.isAnimating) {
      _time.repeat();
    }
  }

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wire = context.isDark
        ? const Color(0xFF6A7C71)
        : const Color(0xFF2E3B33);
    return IgnorePointer(
      child: SizedBox(
        height: LightsString.height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LightsPainter(_time, wire, blink: !_animationsOff(context)),
        ),
      ),
    );
  }
}

class _LightsPainter extends CustomPainter {
  static const List<Color> _colors = [
    Color(0xFFE8443F),
    Color(0xFFF2C14E),
    Color(0xFF3BAE6A),
    Color(0xFF4C8DF0),
  ];
  static const double _spacing = 43;
  static const double _swag = 92;

  final Animation<double> time;
  final Color wire;
  final bool blink;

  _LightsPainter(this.time, this.wire, {required this.blink})
    : super(repaint: time);

  // The wire sags between hooks every [_swag] px.
  double _wireY(double x) => 4 + 9 * sin(((x + 6) / _swag) * pi).abs();

  @override
  void paint(Canvas canvas, Size size) {
    final wirePaint = Paint()
      ..color = wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..moveTo(0, _wireY(0));
    for (double x = 2; x <= size.width; x += 2) {
      path.lineTo(x, _wireY(x));
    }
    canvas.drawPath(path, wirePaint);

    final capPaint = Paint()..color = wire;
    final bulbPaint = Paint();
    var i = 0;
    for (double x = 22; x < size.width - 4; x += _spacing, i++) {
      final y = _wireY(x);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 2.5, y - 1, 5, 4),
          const Radius.circular(1),
        ),
        capPaint,
      );
      // Each bulb fades between full and a quarter at its own pace.
      final rate = 1 + (i % 3);
      final wave = blink
          ? 0.5 + 0.5 * cos((time.value * rate + i * 0.15) * pi * 2)
          : 1.0;
      bulbPaint.color = _colors[i % _colors.length].withValues(
        alpha: 0.25 + 0.75 * wave,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 8), width: 8, height: 12),
        bulbPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LightsPainter oldDelegate) =>
      oldDelegate.wire != wire || oldDelegate.blink != blink;
}

/// Snow behind and lights above [child] at Christmas; nothing otherwise.
/// Ghosts, spiders and pumpkins are placed by the screens themselves
/// (HalloweenDecor).
class SeasonBackdrop extends StatelessWidget {
  final Widget child;

  const SeasonBackdrop({super.key, required this.child});

  /// Extra top padding the screens need to stay clear of the lights.
  static double topInset(BuildContext context) =>
      context.season == Season.christmas ? LightsString.height - 12 : 0;

  @override
  Widget build(BuildContext context) {
    // Same tree in every season: swapping it would rebuild [child] from
    // scratch (losing the open tab and its state) when the season changes.
    // The animated layers get their own repaint boundary so they don't
    // repaint the whole screen every frame.
    final christmas = context.season == Season.christmas;
    return Stack(
      children: [
        Positioned.fill(
          child: christmas
              ? const RepaintBoundary(child: SnowLayer())
              : const SizedBox.shrink(),
        ),
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: christmas
              ? const RepaintBoundary(child: LightsString())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// The drawing for a special calendar day, sized to a 46 x 50 day cell.
class SpecialDayArt extends StatelessWidget {
  final SpecialDay day;

  const SpecialDayArt(this.day, {super.key});

  /// Where the day number sits on the drawing, and its color.
  static ({double top, double left, Color color}) numberStyle(
    SpecialDay day,
    bool dark,
  ) {
    switch (day) {
      case SpecialDay.halloween:
        return (top: 8, left: 0, color: const Color(0xFF2B1838));
      case SpecialDay.christmasEve:
        return (top: 8, left: 0, color: const Color(0xFFFFF8EC));
      case SpecialDay.christmasDay:
        return (top: 9, left: 0, color: const Color(0xFFFFFFFF));
      case SpecialDay.boxingDay:
        return (top: 10, left: 0, color: const Color(0xFFFFFFFF));
      case SpecialDay.newYearsEve:
        return (
          top: 4,
          left: -4,
          color: dark ? const Color(0xFFFFF8EC) : const Color(0xFF13261C),
        );
    }
  }

  static String _circle(double cx, double cy, double r) =>
      'M${cx - r} ${cy}a$r $r 0 1 0 ${2 * r} 0a$r $r 0 1 0 -${2 * r} 0Z';

  static String svg(SpecialDay day, bool dark) {
    final String body;
    switch (day) {
      case SpecialDay.halloween:
        body = '''
<g transform="translate(23 30) scale(0.75) translate(-23 -30)">
<path d="M23 13C8 13 3 23 3 32C3 43 12 49 23 49C34 49 43 43 43 32C43 23 38 13 23 13Z" fill="#F2852B"/>
<path d="M15 15C10 25 10 39 15 48M31 15C36 25 36 39 31 48" fill="none" stroke="#D0661A" stroke-width="1.6"/>
<path d="M23 14C22 9 24 6 28 4" fill="none" stroke="#4E6B2A" stroke-width="3" stroke-linecap="round"/>
<path d="M24 10C28 7 32 9 33 12C29 13 26 12 24 10Z" fill="#4E8A2E"/>
</g>''';
      case SpecialDay.christmasEve:
        body =
            '''
<path d="M20 43H26V49H20Z" fill="#7A4B2A"/>
<path d="M23 6L33 20H28L37 31H31L41 43H5L15 31H9L18 20H13Z" fill="#2E7D4F"/>
<path d="${_circle(17, 28, 2)}" fill="#D3343A"/>
<path d="${_circle(29.5, 24, 1.8)}" fill="#F2C14E"/>
<path d="${_circle(13.5, 39.5, 2)}" fill="#4C8DF0"/>
<path d="${_circle(33, 38.5, 2)}" fill="#D3343A"/>
<path d="${_circle(23, 17, 1.6)}" fill="#4C8DF0"/>
<path d="M23 0L24.4 3.2L27.9 3.5L25.2 5.8L26 9.2L23 7.4L20 9.2L20.8 5.8L18.1 3.5L21.6 3.2Z" fill="#F2C14E"/>''';
      case SpecialDay.christmasDay:
        body =
            '''
<path d="${_circle(23, 31, 17)}" fill="#D3343A"/>
<path d="M19 11H27V15H19Z" fill="#E7B04A"/>
<path d="M23 11C21 8 25 6 23 3" fill="none" stroke="#E7B04A" stroke-width="1.5" stroke-linecap="round"/>
<path d="M13 26C14 22 17 19 21 18" fill="none" stroke="#F28C8F" stroke-width="2" stroke-linecap="round"/>''';
      case SpecialDay.boxingDay:
        body = '''
<path d="M11 25H35V44Q35 46 33 46H13Q11 46 11 44Z" fill="#D3343A"/>
<path d="M9 19H37V26H9Z" fill="#B82A30"/>
<path d="M21 19H25V46H21Z" fill="#F2C14E"/>
<path d="M23 19C19 11 12 12 14 17C15 19 19 19 23 19Z" fill="#F2C14E"/>
<path d="M23 19C27 11 34 12 32 17C31 19 27 19 23 19Z" fill="#F2C14E"/>
<path d="${_circle(23, 18.5, 1.8)}" fill="#E7B04A"/>''';
      case SpecialDay.newYearsEve:
        final tile = dark ? '#3A3220' : '#F6E6B8';
        body =
            '''
<path d="M10 2H36Q44 2 44 10V40Q44 48 36 48H10Q2 48 2 40V10Q2 2 10 2Z" fill="$tile"/>
<path d="M9 8L11 10M14 5L14.6 7.8" fill="none" stroke="#D3343A" stroke-width="1.4" stroke-linecap="round"/>
<path d="M7 14L9.6 13.2" fill="none" stroke="#4C8DF0" stroke-width="1.4" stroke-linecap="round"/>
<path d="M20 6L21.6 7" fill="none" stroke="#E7B04A" stroke-width="1.4" stroke-linecap="round"/>
<path d="M34 38Q34 39.5 35.5 39.5H38Q39.5 39.5 39.5 38V27Q39.5 24.5 37.8 23V19H35.7V23Q34 24.5 34 27Z" fill="#1F4E33"/>
<path d="M35.4 17.5H38.1V21.5H35.4Z" fill="#E7B04A"/>
<path d="M34 30H39.5V34H34Z" fill="#FFF3D6"/>
<path d="M35 12.5Q36.7 10.5 38.5 12.5L38 14.5H35.5Z" fill="#C8A06A"/>
<path d="${_circle(34, 9, 0.9)}" fill="#E7B04A"/>
<path d="${_circle(39.5, 8.5, 0.8)}" fill="#E7B04A"/>
<path d="${_circle(36.8, 6.8, 0.7)}" fill="#E7B04A"/>''';
    }
    return '<svg viewBox="-6 -6 58 62" xmlns="http://www.w3.org/2000/svg">$body</svg>';
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(svg(day, context.isDark), width: 46, height: 50),
    );
  }
}
