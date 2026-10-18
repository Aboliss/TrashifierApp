import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/helpers/pickup_dates_helper.dart';
import 'package:trashifier_app/helpers/schedule_codec.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/pages/calendar_tab.dart';
import 'package:trashifier_app/pages/home_tab.dart';
import 'package:trashifier_app/pages/settings_page.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/storage_service.dart';
import 'package:trashifier_app/services/transfer_service.dart';
import 'package:trashifier_app/services/widget_service.dart';
import 'package:trashifier_app/widgets/add_pickups_sheet.dart';
import 'package:trashifier_app/widgets/calendar_dialog.dart';
import 'package:trashifier_app/widgets/day_pickups_sheet.dart';
import 'package:trashifier_app/widgets/floating_nav_bar.dart';
import 'package:trashifier_app/widgets/import_dialog.dart';
import 'package:trashifier_app/widgets/swipe_hint.dart';
import 'package:trashifier_app/widgets/season_decor.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// App shell: owns the pickup dates and switches between the Home and
/// Calendar tabs.
class HomePage extends StatefulWidget {
  /// False while the splash screen still covers the page; one-time hints
  /// wait for it.
  final bool ready;

  const HomePage({super.key, this.ready = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final Map<TrashType, List<DateTime>> _dates = {
    for (final type in TrashType.values) type: <DateTime>[],
  };

  final PageController _pages = PageController();
  int _tab = 0;

  // Hidden until storage says the user hasn't swiped to the calendar yet.
  bool _showSwipeHint = false;

  // Whether the first Coming up row should peek once to show Remove.
  bool _showRemoveHint = false;

  ReminderSettingsService? _reminderService;

  // Shared links and files waiting for the dates to load or the splash to
  // go; handled one at a time.
  final List<IncomingSchedule> _pendingIncoming = [];
  bool _loaded = false;
  Locale? _locale;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Before asking for the link or file the app was opened with, so one
    // that arrives in between isn't lost.
    TransferService.listen(_onIncoming);
    _loadFromStorage();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ready && !oldWidget.ready) _processIncoming();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = Provider.of<ReminderSettingsService?>(
      context,
      listen: false,
    );
    if (service != _reminderService) {
      _reminderService?.removeListener(_syncReminders);
      _reminderService = service?..addListener(_syncReminders);
    }

    // Reminder texts and the widgets use the app language; redo them when
    // it changes (in Settings or on the phone).
    final locale = Localizations.maybeLocaleOf(context);
    if (_locale != null && locale != _locale) {
      _syncReminders();
      WidgetService.updateWidget();
    }
    _locale = locale;
  }

  ReminderSettings get _reminderSettings =>
      _reminderService?.settings ?? ReminderSettings.defaults;

  @override
  void dispose() {
    TransferService.stopListening();
    _reminderService?.removeListener(_syncReminders);
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // "Today"/"Tomorrow" labels and the season depend on the current date.
      setState(() {});
      context.read<SeasonService?>()?.refresh();
      WidgetService.updateWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    const navSpace = FloatingNavBar.height + 20;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SeasonBackdrop(
              child: PageView(
                controller: _pages,
                onPageChanged: _onPageChanged,
                children: [
                  // Only the visible tab runs its animations (ghosts, spiders).
                  TickerMode(
                    enabled: _tab == 0,
                    child: HomeTab(
                      datesByType: _dates,
                      onAdd: _openAddPickups,
                      onEditDay: _openDayPickupsSheet,
                      onRemovePickup: _removePickup,
                      actions: [_buildSettingsButton()],
                      // One hint at a time: the calendar one goes first.
                      showRemoveHint:
                          widget.ready && _showRemoveHint && !_showSwipeHint,
                      onRemoveHintShown: _onRemoveHintShown,
                      bottomInset: navSpace,
                    ),
                  ),
                  // Keeps the shown month and selected day while on Home.
                  _KeepAlive(
                    child: TickerMode(
                      enabled: _tab == 1,
                      child: CalendarTab(
                        datesByType: _dates,
                        onEditDay: _openDayPickupsSheet,
                        bottomInset: navSpace,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: navSpace + 12 + MediaQuery.paddingOf(context).bottom,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: widget.ready && _showSwipeHint && _tab == 0 ? 1 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Center(child: SwipeHint()),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: FloatingNavBar(
                index: _tab,
                onSelect: (tab) => _pages.animateToPage(
                  tab,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                ),
                onAdd: _openAddPickups,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int tab) {
    setState(() => _tab = tab);
    if (tab == 1 && _showSwipeHint) {
      setState(() => _showSwipeHint = false);
      StorageService.instance.markSwipeHintSeen();
    }
  }

  void _onRemoveHintShown() {
    if (!_showRemoveHint) return;
    setState(() => _showRemoveHint = false);
    StorageService.instance.markRemoveHintSeen();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          datesByType: _dates,
          onImport: _importSchedule,
          onReschedule: _syncReminders,
          onResetHints: _resetHints,
        ),
      ),
    );
  }

  Widget _buildSettingsButton() {
    final palette = context.palette;

    return Semantics(
      button: true,
      label: context.l10n.settings,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _openSettings,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: palette.chip,
          ),
          child: Icon(Icons.settings_rounded, size: 21, color: palette.ink),
        ),
      ),
    );
  }

  Future<void> _loadFromStorage() async {
    final loaded = <TrashType, List<DateTime>>{};
    for (final type in TrashType.values) {
      try {
        loaded[type] = await StorageService.instance.loadDates(type);
      } catch (e) {
        debugPrint('Failed to load $type: $e');
        loaded[type] = [];
      }
    }

    final seenSwipeHint = await StorageService.instance.hasSeenSwipeHint();
    final seenRemoveHint = await StorageService.instance.hasSeenRemoveHint();

    if (!mounted) return;
    setState(() {
      _dates.addAll(loaded);
      _showSwipeHint = !seenSwipeHint && _tab == 0;
      _showRemoveHint = !seenRemoveHint;
    });

    _loaded = true;
    _checkInitialIncoming();

    // Re-arm reminders on every start: Android drops alarms when the app is
    // force-stopped, updated or the exact alarm permission changes.
    await _syncReminders();
    await WidgetService.updateWidget();
  }

  Future<void> _checkInitialIncoming() async {
    try {
      final incoming = await TransferService.initialIncoming();
      if (incoming != null) _onIncoming(incoming);
    } on TransferException catch (e) {
      // Not on Android, e.g. in widget tests.
      debugPrint('No incoming schedule: $e');
    }
  }

  /// A shared link or file reached the app; it is handled once the dates
  /// have loaded and the splash is gone.
  void _onIncoming(IncomingSchedule incoming) {
    _pendingIncoming.add(incoming);
    _processIncoming();
  }

  Future<void> _processIncoming() async {
    if (!_loaded || !widget.ready || _importing || !mounted) return;
    if (_pendingIncoming.isEmpty) return;
    final incoming = _pendingIncoming.removeAt(0);
    _importing = true;
    try {
      if (incoming.error != null) {
        _showSnackBar(ImportDialog.transferErrorMessage(incoming.error!));
        return;
      }
      final Schedule schedule;
      try {
        schedule = incoming.isLink
            ? ScheduleCodec.decodeLink(incoming.value)
            : ScheduleCodec.decodeFile(incoming.value);
      } on ScheduleFormatException catch (e) {
        _showSnackBar(ImportDialog.errorMessage(e.error));
        return;
      }
      await _importSchedule(
        schedule,
        incoming.isLink ? ImportSource.link : ImportSource.file,
      );
    } finally {
      _importing = false;
    }
    _processIncoming();
  }

  /// Asks whether to add [schedule] to the current dates or replace them,
  /// then saves the result.
  Future<void> _importSchedule(Schedule schedule, ImportSource source) async {
    final currentTotal = _dates.values.fold(0, (sum, l) => sum + l.length);
    final choice = await ImportDialog.show(
      context,
      schedule: schedule,
      source: source,
      currentTotal: currentTotal,
    );
    if (choice == null || !mounted) return;

    final changes = choice == ImportChoice.replace
        ? {
            for (final type in TrashType.values)
              type: [...?schedule.dates[type]],
          }
        : ScheduleCodec.merge(_dates, schedule.dates);
    await _applyDateChanges(changes);
    final total = schedule.total;
    _showSnackBar(L10n.current.importedSnack(total));
  }

  Future<RescheduleResult?> _syncReminders() async {
    // Until the dates have loaded, syncing would cancel every reminder.
    if (!_loaded) return null;
    try {
      return await NotificationHelper.rescheduleAll(_dates, _reminderSettings);
    } catch (e) {
      debugPrint('Failed to sync reminders: $e');
      return null;
    }
  }

  Future<void> _openAddPickups() async {
    final now = DateTime.now();
    final type = await AddPickupsSheet.show(
      context,
      upcomingCounts: {
        for (final entry in _dates.entries)
          entry.key: entry.value
              .where((date) => DateFormatHelper.isFuture(date, now))
              .length,
      },
    );
    if (type == null || !mounted) return;

    final selected = await CalendarDialog.show(
      context,
      type: type,
      datesByType: _dates,
    );
    if (selected == null || !mounted) return;

    await _applyDateChanges({
      type: selected.map(DateFormatHelper.dateOnly).toList()..sort(),
    });
  }

  Future<void> _openDayPickupsSheet(DateTime day) async {
    final selected = await DayPickupsSheet.show(
      context,
      day: day,
      initialTypes: PickupDatesHelper.typesOn(_dates, day),
    );
    if (selected == null || !mounted) return;

    final changes = PickupDatesHelper.setTypesForDay(_dates, day, selected);
    if (changes.isNotEmpty) {
      await _applyDateChanges(changes);
    }
  }

  /// Drops [type]'s pickup on [day], with an Undo on the snack bar.
  Future<void> _removePickup(DateTime day, TrashType type) async {
    // They found the swipe on their own.
    _onRemoveHintShown();
    final before = [..._dates[type]!];
    // Show the snack bar right away; saving and re-arming reminders can take
    // a moment.
    final saving = _applyDateChanges({
      type: before
          .where((date) => !DateFormatHelper.isSameDate(date, day))
          .toList(),
    });

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.removedSnack(
            TrashTypeHelper.getDisplayName(type),
            DateFormatHelper.formatFullDate(day),
          ),
        ),
        // Clear of the floating navigation bar.
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          FloatingNavBar.height + 28 + MediaQuery.paddingOf(context).bottom,
        ),
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => _applyDateChanges({type: before}),
        ),
      ),
    );
    await saving;
  }

  /// Replaces the dates of the given types, then persists them and re-syncs
  /// reminders and the home screen widget.
  Future<void> _applyDateChanges(Map<TrashType, List<DateTime>> changes) async {
    setState(() => _dates.addAll(changes));

    for (final entry in changes.entries) {
      try {
        // Also refreshes the home screen widget.
        await StorageService.instance.saveDates(entry.value, entry.key);
      } catch (e) {
        debugPrint('Failed to save dates: $e');
        _showSnackBar(L10n.current.saveFailed, Colors.red);
      }
    }

    await _syncReminders();
  }

  void _showSnackBar(String message, [Color? color]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: color,
      ),
    );
  }

  /// Brings back the one-time hints (debug panel in Settings).
  Future<void> _resetHints() async {
    await StorageService.instance.resetHints();
    if (!mounted) return;
    setState(() {
      _showSwipeHint = _tab == 0;
      _showRemoveHint = true;
    });
  }
}

/// Keeps a [PageView] page alive while it is scrolled out of view.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
