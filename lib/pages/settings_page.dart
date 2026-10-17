import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';

/// Reminder day and time, theme and seasonal themes.
class SettingsPage extends StatefulWidget {
  /// Used to preview the next reminder.
  final Map<TrashType, List<DateTime>> datesByType;

  const SettingsPage({super.key, required this.datesByType});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (e) {
      debugPrint('Failed to read the app version: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              spacing: 12,
              children: [
                RoundIconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text('Settings', style: AppFonts.headline(30, palette.ink)),
              ],
            ),
            const SizedBox(height: 24),
            _Section(title: 'REMINDERS', child: _buildReminders()),
            const SizedBox(height: 22),
            _Section(title: 'APPEARANCE', child: _buildAppearance()),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminders() {
    final palette = context.palette;
    final service = context.watch<ReminderSettingsService?>();
    final settings = service?.settings ?? ReminderSettings.defaults;

    void update(ReminderSettings next) => service?.update(next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const _Label('Remind me'),
        _Segmented<int>(
          value: settings.daysBefore,
          options: const [
            (1, 'The day before', null),
            (0, 'On pickup day', null),
          ],
          onChanged: (days) => update(settings.copyWith(daysBefore: days)),
        ),
        Divider(height: 1, color: palette.line),
        Semantics(
          button: true,
          label:
              'Reminder time, '
              '${PickupCopyHelper.formatTime(settings.hour, settings.minute)}',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pickTime(settings, update),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                spacing: 12,
                children: [
                  const _IconTile(Icons.schedule_rounded),
                  const Expanded(child: _Label('Time')),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.fab,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      PickupCopyHelper.formatTime(
                        settings.hour,
                        settings.minute,
                      ),
                      style: AppFonts.headline(18, palette.fabInk),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _NextReminder(datesByType: widget.datesByType, settings: settings),
      ],
    );
  }

  Future<void> _pickTime(
    ReminderSettings settings,
    void Function(ReminderSettings) update,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'Reminder time',
    );
    if (picked == null) return;
    update(settings.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Widget _buildAppearance() {
    final palette = context.palette;
    final theme = context.watch<ThemeService>();
    final season = context.watch<SeasonService?>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        const _Label('Theme'),
        _Segmented<ThemeMode>(
          value: theme.themeMode,
          options: const [
            (ThemeMode.system, 'Auto', Icons.brightness_auto_rounded),
            (ThemeMode.light, 'Light', Icons.light_mode_rounded),
            (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
          ],
          onChanged: theme.setTheme,
        ),
        if (season != null) ...[
          Divider(height: 1, color: palette.line),
          MergeSemantics(
            child: Row(
              spacing: 12,
              children: [
                const _IconTile(Icons.celebration_rounded),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      const _Label('Seasonal themes'),
                      Text(
                        'Pumpkin Buddy in October, Santa Buddy in December',
                        style: TextStyle(color: palette.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // Off means "always normal"; a season forced from the
                  // debug panel counts as on.
                  value: season.override != SeasonOverride.normal,
                  activeTrackColor: palette.ink,
                  activeThumbColor: palette.card,
                  onChanged: (on) => season.setOverride(
                    on ? SeasonOverride.auto : SeasonOverride.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    final palette = context.palette;
    final name = _version == null ? 'Trashifier' : 'Trashifier $_version';
    return Column(
      spacing: 4,
      children: [
        Text(name, style: TextStyle(color: palette.muted, fontSize: 13)),
        TextButton(
          onPressed: () => showLicensePage(
            context: context,
            applicationName: 'Trashifier',
            applicationVersion: _version,
          ),
          style: TextButton.styleFrom(foregroundColor: palette.ink),
          child: const Text('Licenses'),
        ),
      ],
    );
  }
}

/// "Next reminder: Sunday, Oct 18 at 7:00 PM · Plastic".
class _NextReminder extends StatelessWidget {
  final Map<TrashType, List<DateTime>> datesByType;
  final ReminderSettings settings;

  const _NextReminder({required this.datesByType, required this.settings});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final next = NotificationHelper.planReminders(
      datesByType,
      settings: settings,
      limit: 1,
    );

    final InlineSpan detail;
    if (next.isEmpty) {
      detail = const TextSpan(text: 'none planned. Add pickups on Home.');
    } else {
      final reminder = next.first;
      detail = TextSpan(
        children: [
          TextSpan(
            text:
                '${DateFormatHelper.formatDayName(reminder.time)}, '
                '${DateFormatHelper.formatDate(reminder.time)} at '
                '${PickupCopyHelper.formatTime(settings.hour, settings.minute)}',
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' · ${TrashTypeHelper.getDisplayName(reminder.type)}'),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.ground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text.rich(
        TextSpan(text: 'Next reminder: ', children: [detail]),
        style: TextStyle(color: palette.muted, fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

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
          padding: const EdgeInsets.all(16),
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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

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

class _IconTile extends StatelessWidget {
  final IconData icon;

  const _IconTile(this.icon);

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
class _Segmented<T> extends StatelessWidget {
  final T value;
  final List<(T, String, IconData?)> options;
  final ValueChanged<T> onChanged;

  const _Segmented({
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
                              child: Text(
                                label,
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
