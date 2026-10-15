import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/widgets/bin_icon.dart';

/// The Trashifier mascot: a bin striped in the four bin colors, with a
/// popped lid and a smile. assets/icon_sources/*.svg hold the same drawing
/// for the launcher icon and splash screen.
class BinBuddy extends StatelessWidget {
  final double size;

  /// Lid color; also decides whether the stripes use the bright on-dark bin
  /// colors.
  final Color lidColor;
  final bool onDark;

  /// Draws the rounded app icon tile behind the mascot.
  final bool asAppIcon;

  const BinBuddy({
    super.key,
    this.size = 40,
    required this.lidColor,
    this.onDark = false,
    this.asAppIcon = false,
    this.lidLift = 0,
  });

  /// The launcher icon: light mascot on an ink tile.
  const BinBuddy.appIcon({super.key, this.size = 64})
    : lidColor = const Color(0xFFF4F5EF),
      onDark = true,
      asAppIcon = true,
      lidLift = 0;

  /// How far the lid floats above the body, in the drawing's 120-unit
  /// grid; animate it to make the lid pop.
  final double lidLift;

  static String _bodySvg({required bool onDark, required bool asAppIcon}) {
    final trash = onDark ? TrashColors.trashOnDark : TrashColors.trashColor;
    final bio = onDark ? TrashColors.bioOnDark : TrashColors.bioColor;
    final tile = asAppIcon
        ? '<rect width="120" height="120" rx="30" fill="#16201B"/>'
        : '';
    // Nudged up on the tile so the mascot sits optically centered.
    final shift = asAppIcon ? 'translate(0 -4)' : 'translate(0 0)';
    return '''
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
$tile
<defs><clipPath id="body"><path d="M30 44H90L85.2 97.5Q84.6 104 78 104H42Q35.4 104 34.8 97.5Z"/></clipPath></defs>
<g transform="$shift">
<g clip-path="url(#body)">
<rect x="30" y="44" width="15" height="60" fill="${svgColor(TrashColors.plasticColor)}"/>
<rect x="45" y="44" width="15" height="60" fill="${svgColor(TrashColors.paperColor)}"/>
<rect x="60" y="44" width="15" height="60" fill="${svgColor(trash)}"/>
<rect x="75" y="44" width="15" height="60" fill="${svgColor(bio)}"/>
</g>
<circle cx="52" cy="66" r="6.5" fill="#FFFFFF"/><circle cx="53.5" cy="64.5" r="3" fill="#16201B"/>
<circle cx="68" cy="66" r="6.5" fill="#FFFFFF"/><circle cx="69.5" cy="64.5" r="3" fill="#16201B"/>
<path d="M51 80Q60 88 69 80" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/>
</g>
</svg>''';
  }

  static String _lidSvg({required Color lidColor, required bool asAppIcon}) {
    final lid = svgColor(lidColor);
    final shift = asAppIcon ? 'translate(0 -4)' : 'translate(0 0)';
    return '''
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
<g transform="$shift"><g transform="rotate(-12 60 36)">
<rect x="24" y="31" width="72" height="10" rx="5" fill="$lid"/>
<rect x="50" y="24" width="20" height="9" rx="4.5" fill="$lid"/>
</g></g>
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
              _bodySvg(onDark: onDark, asAppIcon: asAppIcon),
              width: size,
              height: size,
            ),
            Transform.translate(
              offset: Offset(0, -lidLift * size / 120),
              child: SvgPicture.string(
                _lidSvg(lidColor: lidColor, asAppIcon: asAppIcon),
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
