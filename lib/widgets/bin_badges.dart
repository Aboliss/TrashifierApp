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
