import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/widgets/bin_icon.dart';

/// The Trashifier mascot: a bin striped in the four bin colors, with a
/// popped lid and a smile. assets/icon_sources/*.svg hold the same drawing
/// for the launcher icon and splash screen.
///
/// In season he wears a [costume]: a carved pumpkin for Halloween, a Santa
/// hat for Christmas.
class BinBuddy extends StatelessWidget {
  final double size;

  /// Lid color; also decides whether the stripes use the bright on-dark bin
  /// colors.
  final Color lidColor;
  final bool onDark;

  /// Draws the rounded app icon tile behind the mascot.
  final bool asAppIcon;

  /// How far the lid (or hat) floats above the body, in the drawing's
  /// 120-unit grid; animate it to make the lid pop.
  final double lidLift;

  final BuddyCostume costume;

  const BinBuddy({
    super.key,
    this.size = 40,
    required this.lidColor,
    this.onDark = false,
    this.asAppIcon = false,
    this.lidLift = 0,
    this.costume = BuddyCostume.normal,
  });

  /// The launcher icon: light mascot on an ink tile.
  const BinBuddy.appIcon({super.key, this.size = 64})
    : lidColor = const Color(0xFFF4F5EF),
      onDark = true,
      asAppIcon = true,
      lidLift = 0,
      costume = BuddyCostume.normal;

  static const String _bodyPath =
      'M30 44H90L85.2 97.5Q84.6 104 78 104H42Q35.4 104 34.8 97.5Z';

  static const String _eyesAndSmile = '''
<circle cx="52" cy="66" r="6.5" fill="#FFFFFF"/><circle cx="53.5" cy="64.5" r="3" fill="#16201B"/>
<circle cx="68" cy="66" r="6.5" fill="#FFFFFF"/><circle cx="69.5" cy="64.5" r="3" fill="#16201B"/>
<path d="M51 80Q60 88 69 80" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>''';

  static String _bodySvg({
    required bool onDark,
    required bool asAppIcon,
    required BuddyCostume costume,
  }) {
    final trash = onDark ? TrashColors.trashOnDark : TrashColors.trashColor;
    final bio = onDark ? TrashColors.bioOnDark : TrashColors.bioColor;
    final tile = asAppIcon
        ? '<rect width="120" height="120" rx="30" fill="#16201B"/>'
        : '';
    // Nudged up on the tile so the mascot sits optically centered.
    final shift = asAppIcon ? 'translate(0 -4)' : 'translate(0 0)';

    final String body;
    if (costume == BuddyCostume.pumpkin) {
      // Carved jack-o'-lantern: orange with ribs and a toothy grin.
      body =
          '''
<path d="$_bodyPath" fill="#F2852B"/>
<g clip-path="url(#body)" fill="none" stroke="#D0661A" stroke-width="3">
<path d="M45 44Q40 74 45 104"/><path d="M60 44V104"/><path d="M75 44Q80 74 75 104"/>
</g>
<path d="M44 71L51 59L58 71Z" fill="#2B1838"/>
<path d="M62 71L69 59L76 71Z" fill="#2B1838"/>
<path d="M43 79H77L73 88L68 84L64 91L60 85L56 91L52 84L47 88Z" fill="#2B1838"/>''';
    } else {
      body =
          '''
<g clip-path="url(#body)">
<rect x="30" y="44" width="15" height="60" fill="${svgColor(TrashColors.plasticColor)}"/>
<rect x="45" y="44" width="15" height="60" fill="${svgColor(TrashColors.paperColor)}"/>
<rect x="60" y="44" width="15" height="60" fill="${svgColor(trash)}"/>
<rect x="75" y="44" width="15" height="60" fill="${svgColor(bio)}"/>
</g>
$_eyesAndSmile''';
    }

    return '''
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
$tile
<defs><clipPath id="body"><path d="$_bodyPath"/></clipPath></defs>
<g transform="$shift">
$body
</g>
</svg>''';
  }

  static String _lidSvg({
    required Color lidColor,
    required bool asAppIcon,
    required BuddyCostume costume,
  }) {
    final lid = svgColor(lidColor);
    final shift = asAppIcon ? 'translate(0 -4)' : 'translate(0 0)';

    final String top;
    switch (costume) {
      case BuddyCostume.pumpkin:
        // Leafy green lid with a curly stem.
        top = '''
<g transform="rotate(-12 60 36)">
<rect x="24" y="31" width="72" height="10" rx="5" fill="#3F7D2A"/>
<path d="M60 31Q58 22 64 16" fill="none" stroke="#6B4A2B" stroke-width="5" stroke-linecap="round"/>
<path d="M64 20q8 -6 13 0" fill="none" stroke="#3F7D2A" stroke-width="3" stroke-linecap="round"/>
</g>''';
      case BuddyCostume.santa:
        top = '''
<g transform="rotate(-10 60 36)">
<path d="M32 38C38 14 64 6 84 14C95 18 101 26 101 36L92 38C88 30 82 26 76 27C70 30 66 34 64 38Z" fill="#D3343A"/>
<rect x="24" y="33" width="72" height="11" rx="5.5" fill="#FFFFFF" stroke="#DADFD8" stroke-width="1"/>
<circle cx="100" cy="38" r="6.5" fill="#FFFFFF" stroke="#DADFD8" stroke-width="1"/>
</g>''';
      case BuddyCostume.normal:
        top =
            '''
<g transform="rotate(-12 60 36)">
<rect x="24" y="31" width="72" height="10" rx="5" fill="$lid"/>
<rect x="50" y="24" width="20" height="9" rx="4.5" fill="$lid"/>
</g>''';
    }

    return '''
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
<g transform="$shift">$top</g>
</svg>''';
  }

  @override
  Widget build(BuildContext context) {
    // Two layers so the lid can move on its own without re-parsing the SVG.
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            SvgPicture.string(
              _bodySvg(onDark: onDark, asAppIcon: asAppIcon, costume: costume),
              width: size,
              height: size,
            ),
            Transform.translate(
              offset: Offset(0, -lidLift * size / 120),
              child: SvgPicture.string(
                _lidSvg(
                  lidColor: lidColor,
                  asAppIcon: asAppIcon,
                  costume: costume,
                ),
                width: size,
                height: size,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
