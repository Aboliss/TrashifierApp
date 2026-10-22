import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trashifier_app/models/bin_style.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// A bin's stroke icon, from [BinStyle.icons].
///
/// The same shapes are used by the Android widget drawables
/// (res/drawable/ic_bin_*.xml).
class BinIcon extends StatelessWidget {
  final TrashType type;
  final Color color;
  final double size;

  const BinIcon(this.type, {super.key, required this.color, this.size = 22});

  static String svg(TrashType type, Color color, {double strokeWidth = 2}) {
    final hex = _hex(color);
    final body = BinStyle.icon(type.icon).map((d) => '<path d="$d"/>').join();
    return '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" '
        'fill="none" stroke="$hex" stroke-width="$strokeWidth" '
        'stroke-linecap="round" stroke-linejoin="round">$body</svg>';
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SvgPicture.string(svg(type, color), width: size, height: size),
    );
  }
}

String _hex(Color color) {
  final argb = color.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// `#RRGGBB` for embedding a color in SVG markup.
String svgColor(Color color) => _hex(color);
