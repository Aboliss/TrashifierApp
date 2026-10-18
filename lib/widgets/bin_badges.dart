import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_icon.dart';

/// Rounded, bin-colored label with the bin's icon: "[bottle] Plastic".
class BinPill extends StatelessWidget {
  final TrashType type;
  final double height;
  final bool showIcon;

  const BinPill(this.type, {super.key, this.height = 40, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    final fg = TrashColors.getContainerTextColor(context, type);
    return Container(
      height: height,
      padding: EdgeInsets.only(
        left: showIcon ? height * 0.3 : height * 0.4,
        right: height * 0.4,
      ),
      decoration: BoxDecoration(
        color: TrashColors.getContainerColor(context, type),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          if (showIcon) BinIcon(type, color: fg, size: height * 0.5),
          Text(
            TrashTypeHelper.getShortName(type),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: height * 0.37,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bin-colored rounded square holding the bin's icon.
class BinIconTile extends StatelessWidget {
  final TrashType type;
  final double size;

  const BinIconTile(this.type, {super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TrashColors.getContainerColor(context, type),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: BinIcon(
        type,
        color: TrashColors.getContainerTextColor(context, type),
        size: size * 0.48,
      ),
    );
  }
}

/// Small bin-colored dot or bar, e.g. under a calendar day.
class BinMark extends StatelessWidget {
  final TrashType type;
  final double width;
  final double height;

  /// Uses the brighter on-dark colors, for marks on the hero card.
  final bool onDark;

  const BinMark(
    this.type, {
    super.key,
    this.width = 8,
    this.height = 8,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onDark || context.isDark
        ? TrashColors.getMarkColorOnDark(type)
        : TrashColors.getColorByType(type);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}

/// A row of [BinMark]s for the bins on one day: all of them up to
/// [maxMarks], else one fewer and a "+N".
class BinMarkRow extends StatelessWidget {
  final List<TrashType> types;
  final double markWidth;
  final double markHeight;
  final double spacing;
  final bool onDark;
  final int maxMarks;

  /// The marks share this width (bars), instead of [markWidth] each.
  final double? totalWidth;

  const BinMarkRow(
    this.types, {
    super.key,
    this.markWidth = 8,
    this.markHeight = 8,
    this.spacing = 3,
    this.onDark = false,
    this.maxMarks = 4,
    this.totalWidth,
  });

  @override
  Widget build(BuildContext context) {
    final overflow = types.length > maxMarks;
    final shown = overflow ? types.take(maxMarks - 1).toList() : types;
    final width = totalWidth == null || shown.isEmpty
        ? markWidth
        // Never thinner than 6 px, so "+N" days stay readable.
        : ((totalWidth! - (overflow ? 12 : 0)) / shown.length - spacing).clamp(
            6.0,
            totalWidth!,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: spacing,
      children: [
        for (final type in shown)
          BinMark(type, width: width, height: markHeight, onDark: onDark),
        if (overflow)
          Text(
            '+${types.length - shown.length}',
            style: TextStyle(
              color: context.palette.muted,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              height: 1,
            ),
          ),
      ],
    );
  }
}

/// 44 px round icon button on a chip background.
class RoundIconButton extends StatelessWidget {
  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? background;
  final Color? foreground;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: background ?? palette.chip,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: IconTheme(
              data: IconThemeData(color: foreground ?? palette.ink, size: 20),
              child: Center(child: icon),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width pill button: filled ink, or outlined.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );
    const textStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    const size = Size.fromHeight(56);

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          shape: shape,
          foregroundColor: palette.ink,
          side: BorderSide(color: palette.ink, width: 2),
          textStyle: textStyle,
        ),
        child: Text(label),
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: size,
        shape: shape,
        backgroundColor: palette.ink,
        foregroundColor: palette.ground,
        textStyle: textStyle,
      ),
      child: Text(label),
    );
  }
}
