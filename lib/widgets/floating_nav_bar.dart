import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// Pill-shaped bottom bar: Home and Calendar tabs plus the yellow add button.
class FloatingNavBar extends StatelessWidget {
  static const double height = 68;

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  const FloatingNavBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.nav,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x400A140F),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        spacing: 4,
        children: [
          // Tabs shrink (labels fade) only on narrow screens or with large
          // text.
          Expanded(
            child: Row(
              spacing: 4,
              children: [
                Flexible(
                  child: _tab(
                    palette,
                    0,
                    Icons.home_outlined,
                    context.l10n.navHome,
                  ),
                ),
                Flexible(
                  child: _tab(
                    palette,
                    1,
                    Icons.calendar_month_outlined,
                    context.l10n.navCalendar,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: context.l10n.addPickups,
            excludeSemantics: true,
            child: Material(
              color: palette.fab,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onAdd,
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.add_rounded,
                    size: 30,
                    color: palette.fabInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(AppPalette palette, int tab, IconData icon, String label) {
    final active = index == tab;
    final fg = active ? palette.navActiveInk : palette.navInk;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? palette.navActive : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onSelect(tab),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Icon(icon, size: 20, color: fg),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: fg,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
