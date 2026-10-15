import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trashifier_app/models/trash_type.dart';

/// Stroke icon for a bin type: bottle, paper sheet, trash can or leaf.
///
/// The same shapes are used by the Android widget drawables
/// (res/drawable/ic_bin_*.xml).
class BinIcon extends StatelessWidget {
  final TrashType type;
  final Color color;
  final double size;

  const BinIcon(this.type, {super.key, required this.color, this.size = 22});

  static const Map<TrashType, List<String>> paths = {
    TrashType.plastic: [
      'M10 2.5h4',
      'M10.5 2.5v2.8L8.2 8.6A2 2 0 0 0 8 9.6V19.5a2 2 0 0 0 2 2h4a2 2 0 0 0 '
          '2-2V9.6a2 2 0 0 0-.2-1L13.5 5.3V2.5',
      'M8 13h8',
    ],
    TrashType.paper: ['M6 3h8.5L19 7.5V21H6Z', 'M14 3v5h5', 'M9 13h7M9 17h5'],
    TrashType.trash: [
      'M4 6.5h16',
      'M9 6.5V4h6v2.5',
      'M6.5 6.5 7.5 21h9l1-14.5M10 10.5v6.5M14 10.5v6.5',
    ],
    TrashType.bio: [
      'M20 4C11 4 5 8.5 5 15.5c0 1.6.4 3 1 4.5 1.5.6 2.9 1 4.5 1C17 21 20 13 '
          '20 4Z',
      'M4 21c3-5 6.5-8.5 11-11',
    ],
  };

  static String svg(TrashType type, Color color, {double strokeWidth = 2}) {
    final hex = _hex(color);
    final body = paths[type]!.map((d) => '<path d="$d"/>').join();
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
