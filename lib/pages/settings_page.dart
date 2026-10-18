import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_copy_helper.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/locale_service.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/theme_service.dart';
import 'package:trashifier_app/services/transfer_service.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/import_dialog.dart';
import 'package:trashifier_app/widgets/share_qr_sheet.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// Reminder day and time, theme and seasonal themes.
class SettingsPage extends StatefulWidget {
  /// Used to preview the next reminder, and to back up and share.
  final Map<TrashType, List<DateTime>> datesByType;

  /// Asks the user how to import [schedule] and applies it (the home page
  /// owns the dates).
  final Future<void> Function(Schedule schedule, ImportSource source) onImport;

  const SettingsPage({
    super.key,
    required this.datesByType,
    required this.onImport,
  });

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
                  tooltip: context.l10n.back,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Text(
                  context.l10n.settings,
                  style: AppFonts.headline(30, palette.ink),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              title: context.l10n.sectionReminders,
              child: _buildReminders(),
            ),
            const SizedBox(height: 22),
            _Section(
              title: context.l10n.sectionAppearance,
              child: _buildAppearance(),
            ),
            const SizedBox(height: 22),
            _Section(
              title: context.l10n.sectionBackup,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildBackup(),
            ),
            const SizedBox(height: 22),
            _Section(title: context.l10n.sectionShare, child: _buildShare()),
            const SizedBox(height: 28),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildReminders() {
    final palette = context.palette;
    final l = context.l10n;
    final service = context.watch<ReminderSettingsService?>();
    final settings = service?.settings ?? ReminderSettings.defaults;

    void update(ReminderSettings next) => service?.update(next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _Label(l.remindMe),
        _Segmented<int>(
          value: settings.daysBefore,
          options: [(1, l.theDayBefore, null), (0, l.onPickupDay, null)],
          onChanged: (days) => update(settings.copyWith(daysBefore: days)),
        ),
        Divider(height: 1, color: palette.line),
        Semantics(
          button: true,
          label: l.reminderTimeA11y(
            PickupCopyHelper.formatTime(settings.hour, settings.minute),
          ),
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
                  Expanded(child: _Label(l.time)),
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
      helpText: context.l10n.reminderTime,
    );
    if (picked == null) return;
    update(settings.copyWith(hour: picked.hour, minute: picked.minute));
  }

  Widget _buildAppearance() {
    final palette = context.palette;
    final l = context.l10n;
    final theme = context.watch<ThemeService>();
    final season = context.watch<SeasonService?>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _ActionRow(
          icon: Icons.translate_rounded,
          title: l.language,
          subtitle: _languageLabel(),
          onTap: _pickLanguage,
        ),
        Divider(height: 1, color: palette.line),
        _Label(l.theme),
        _Segmented<ThemeMode>(
          value: theme.themeMode,
          options: [
            (ThemeMode.system, l.themeAuto, Icons.brightness_auto_rounded),
            (ThemeMode.light, l.themeLight, Icons.light_mode_rounded),
            (ThemeMode.dark, l.themeDark, Icons.dark_mode_rounded),
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
                      _Label(l.seasonalThemes),
                      Text(
                        l.seasonalThemesHint,
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

  Widget _buildBackup() {
    final palette = context.palette;
    return Column(
      children: [
        _ActionRow(
          icon: Icons.download_rounded,
          title: context.l10n.exportBackup,
          subtitle: context.l10n.exportBackupHint,
          onTap: _exportBackup,
        ),
        Divider(height: 1, color: palette.line),
        _ActionRow(
          icon: Icons.upload_rounded,
          title: context.l10n.importTitle,
          subtitle: context.l10n.importHint,
          onTap: _import,
        ),
      ],
    );
  }

  Widget _buildShare() {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: _ShareTile(
                icon: Icons.share_rounded,
                label: context.l10n.sendAsFile,
                background: const Color(0xFF2F6BEA),
                foreground: Colors.white,
                onTap: _shareFile,
              ),
            ),
            Expanded(
              child: _ShareTile(
                icon: Icons.qr_code_2_rounded,
                label: context.l10n.showQrCode,
                background: palette.fab,
                foreground: palette.fabInk,
                onTap: _showQr,
              ),
            ),
          ],
        ),
        Text(
          context.l10n.shareHint,
          style: TextStyle(color: palette.muted, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  /// "Phone language (English)" or the picked language's own name.
  String _languageLabel() {
    final language = context.watch<LocaleService?>()?.language;
    if (language != null && language != LocaleService.system) {
      return LocaleService.nativeNames[language] ?? language;
    }
    final active = Localizations.localeOf(context).languageCode;
    return context.l10n.phoneLanguageNow(
      LocaleService.nativeNames[active] ?? active,
    );
  }

  Future<void> _pickLanguage() async {
    final service = context.read<LocaleService?>();
    if (service == null) return;
    final picked = await _LanguageSheet.show(context, service.language);
    if (picked != null) await service.setLanguage(picked);
  }

  Future<void> _exportBackup() async {
    final now = DateTime.now();
    final content = ScheduleCodec.encodeFile(widget.datesByType, now: now);
    try {
      final saved = await TransferService.saveFile(
        'trashifier-backup-${_fileDate(now)}.json',
        content,
      );
      if (saved) _snack(L10n.current.backupSaved);
    } on TransferException catch (e) {
      _snack(ImportDialog.transferErrorMessage(e.error));
    }
  }

  Future<void> _import() async {
    final source = await _ImportSourceSheet.show(context);
    if (source == null || !mounted) return;
    try {
      final String? text = source == ImportSource.qr
          ? await TransferService.scanQr()
          : await TransferService.openFile();
      if (text == null || !mounted) return;
      final schedule = source == ImportSource.qr
          ? ScheduleCodec.decodeLink(text)
          : ScheduleCodec.decodeFile(text);
      await widget.onImport(schedule, source);
      // The preview may now show a different next reminder.
      if (mounted) setState(() {});
    } on TransferException catch (e) {
      _snack(
        source == ImportSource.qr && e.error == TransferError.unavailable
            ? L10n.current.scannerUnavailable
            : ImportDialog.transferErrorMessage(e.error),
      );
    } on ScheduleFormatException catch (e) {
      _snack(ImportDialog.errorMessage(e.error));
    }
  }

  Future<void> _shareFile() async {
    final now = DateTime.now();
    final content = ScheduleCodec.encodeFile(
      widget.datesByType,
      now: now,
      from: now,
    );
    if (!_hasUpcoming(now)) {
      _snack(L10n.current.nothingToShare);
      return;
    }
    try {
      await TransferService.shareFile(
        'trashifier-schedule.json',
        content,
        title: L10n.current.shareTitle,
      );
    } on TransferException catch (e) {
      _snack(ImportDialog.transferErrorMessage(e.error));
    }
  }

  Future<void> _showQr() async {
    final shown = await ShareQrSheet.show(
      context,
      datesByType: widget.datesByType,
      onSendFile: _shareFile,
    );
    if (!shown) _snack(L10n.current.nothingToShare);
  }

  bool _hasUpcoming(DateTime now) {
    final today = DateFormatHelper.dateOnly(now);
    return widget.datesByType.values.any(
      (dates) => dates.any((date) => !date.isBefore(today)),
    );
  }

  static String _fileDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          child: Text(context.l10n.licenses),
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
    final l = context.l10n;
    final next = NotificationHelper.planReminders(
      datesByType,
      settings: settings,
      limit: 1,
    );

    final InlineSpan detail;
    if (next.isEmpty) {
      return _box(palette, Text(l.nextReminderNone, style: _style(palette)));
    } else {
      final reminder = next.first;
      detail = TextSpan(
        children: [
          TextSpan(
            text: l.nextReminderAt(
              DateFormatHelper.formatFullDate(reminder.time),
              PickupCopyHelper.formatTime(settings.hour, settings.minute),
            ),
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' · ${TrashTypeHelper.getDisplayName(reminder.type)}'),
        ],
      );
    }

    return _box(
      palette,
      Text.rich(
        TextSpan(text: l.nextReminderLabel, children: [detail]),
        style: _style(palette),
      ),
    );
  }

  static TextStyle _style(AppPalette palette) =>
      TextStyle(color: palette.muted, fontSize: 13, height: 1.4);

  static Widget _box(AppPalette palette, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: palette.ground,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets padding;

  const _Section({
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

/// A tappable row with an icon tile, a title and a hint.
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
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
              _IconTile(icon),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    _Label(title),
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

class _ShareTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _ShareTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Icon(icon, color: foreground, size: 24),
                Text(
                  label,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

/// Asks where to import from: a file or a QR code.
class _ImportSourceSheet extends StatelessWidget {
  const _ImportSourceSheet();

  static Future<ImportSource?> show(BuildContext context) {
    return showModalBottomSheet<ImportSource>(
      context: context,
      builder: (_) => const _ImportSourceSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.importTitle, style: AppFonts.headline(24, palette.ink)),
            const SizedBox(height: 4),
            Text(
              l.importSheetHint,
              style: TextStyle(color: palette.muted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _ActionRow(
              icon: Icons.description_outlined,
              title: l.fromFile,
              subtitle: l.fromFileHint,
              onTap: () => Navigator.of(context).pop(ImportSource.file),
            ),
            Divider(height: 1, color: palette.line),
            _ActionRow(
              icon: Icons.qr_code_scanner_rounded,
              title: l.scanQrCode,
              subtitle: l.scanQrCodeHint,
              onTap: () => Navigator.of(context).pop(ImportSource.qr),
            ),
          ],
        ),
      ),
    );
  }
}

/// Phone language or one of the translations, each in its own language.
class _LanguageSheet extends StatelessWidget {
  final String current;

  const _LanguageSheet({required this.current});

  static Future<String?> show(BuildContext context, String current) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = context.l10n;
    final options = [
      (LocaleService.system, l.phoneLanguage),
      for (final code in LocaleService.languages)
        (code, LocaleService.nativeNames[code]!),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(l.language, style: AppFonts.headline(24, palette.ink)),
            Text(
              l.languageHint,
              style: TextStyle(color: palette.muted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            for (final (code, name) in options)
              _LanguageOption(
                name: name,
                selected: code == current,
                onTap: () => Navigator.of(context).pop(code),
              ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? palette.chip : palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? palette.ink : palette.line,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: palette.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? palette.ink : palette.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
