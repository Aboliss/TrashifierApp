import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';

// Building blocks of the Settings page, also used by the debug section.

class SettingsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets padding;

  const SettingsSection({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Semantics(
            header: true,
            child: Text(title, style: AppFonts.eyebrow(palette.muted)),
          ),
        ),
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ],
    );
  }
}

class SettingsLabel extends StatelessWidget {
  final String text;

  const SettingsLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.palette.ink,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );
  }
}

class SettingsIconTile extends StatelessWidget {
  final IconData icon;

  const SettingsIconTile(this.icon, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: palette.ink),
    );
  }
}

/// A row of equal-width choices; the selected one is filled with ink.
class SettingsSegmented<T> extends StatelessWidget {
  final T value;
  final List<(T, String, IconData?)> options;
  final ValueChanged<T> onChanged;

  const SettingsSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 4,
        children: [
          for (final (option, label, icon) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == value,
                child: Material(
                  color: option == value ? palette.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onChanged(option),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 6,
                          children: [
                            if (icon != null)
                              Icon(
                                icon,
                                size: 17,
                                color: option == value
                                    ? palette.ground
                                    : palette.ink,
                              ),
                            Flexible(
                              // Shrinks rather than wraps when space is tight.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: option == value
                                        ? palette.ground
                                        : palette.ink,
                                    fontWeight: option == value
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tappable row with an icon tile, a title and a hint.
class SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              SettingsIconTile(icon),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    SettingsLabel(title),
                    Text(
                      subtitle,
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }
}
