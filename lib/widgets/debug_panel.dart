import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/constants/trash_colors.dart';
import 'package:trashifier_app/helpers/date_format_helper.dart';
import 'package:trashifier_app/helpers/notification_helper.dart';
import 'package:trashifier_app/models/reminder_settings.dart';
import 'package:trashifier_app/models/season.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/services/notifications_service.dart';
import 'package:trashifier_app/services/reminder_settings_service.dart';
import 'package:trashifier_app/services/season_service.dart';
import 'package:trashifier_app/services/widget_service.dart';
import 'package:trashifier_app/widgets/settings_tiles.dart';

/// Developer tools as Settings sections, hidden until the version text is
/// held for five seconds: inspect and test reminders, reset hints, refresh
/// the widgets and force a seasonal theme. English only.
class DebugPanel extends StatefulWidget {
  static const int testNotificationId = 999;

  final Map<TrashType, List<DateTime>> datesByType;

  /// Re-arms every reminder; null when not available (e.g. in tests).
  final Future<RescheduleResult?> Function()? onReschedule;

  /// Brings back the one-time hints on Home.
  final Future<void> Function()? onResetHints;

  const DebugPanel({
    super.key,
    required this.datesByType,
    this.onReschedule,
    this.onResetHints,
  });

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  static const _rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final season = context.watch<SeasonService?>();
    Widget divider() => Divider(height: 1, color: palette.line);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 22,
      children: [
        SettingsSection(
          title: 'DEBUG · REMINDERS',
          padding: _rowPadding,
          child: Column(
            children: [
              SettingsActionRow(
                icon: Icons.event_note_rounded,
                title: 'Reminder plan',
                subtitle: 'Planned reminders and permissions',
                onTap: _debugNotificationScheduling,
              ),
              divider(),
              SettingsActionRow(
                icon: Icons.pending_actions_rounded,
                title: 'Pending reminders',
                subtitle: 'What Android has scheduled',
                onTap: _showPendingNotifications,
              ),
              divider(),
              SettingsActionRow(
                icon: Icons.notifications_active_rounded,
                title: 'Test notification',
                subtitle: 'Arrives in 10 seconds',
                onTap: _scheduleTestNotification,
              ),
            ],
          ),
        ),
        SettingsSection(
          title: 'DEBUG · APP',
          padding: _rowPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsActionRow(
                icon: Icons.restart_alt_rounded,
                title: 'Reset hints',
                subtitle: 'Show the swipe hints on Home again',
                onTap: _resetHints,
              ),
              divider(),
              SettingsActionRow(
                icon: Icons.widgets_rounded,
                title: 'Update widgets',
                subtitle: 'Redraw the home screen widgets now',
                onTap: _debugWidget,
              ),
              if (season != null) ...[
                divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      const Row(
                        spacing: 12,
                        children: [
                          SettingsIconTile(Icons.celebration_rounded),
                          Expanded(child: SettingsLabel('Force a season')),
                        ],
                      ),
                      SettingsSegmented<SeasonOverride>(
                        value: season.override,
                        options: const [
                          (SeasonOverride.auto, 'Auto', null),
                          (SeasonOverride.normal, 'Normal', null),
                          (SeasonOverride.halloween, 'Halloween', null),
                          (SeasonOverride.christmas, 'Christmas', null),
                        ],
                        onChanged: season.setOverride,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resetHints() async {
    await widget.onResetHints?.call();
    _showSnackBar('Hints will show again');
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

  Future<void> _scheduleTestNotification() async {
    try {
      await NotificationService.scheduleNotification(
        DebugPanel.testNotificationId,
        'Test Notification',
        'This is a test notification scheduled 10 seconds ago!',
        DateTime.now().add(const Duration(seconds: 10)),
        exact: await NotificationService.canScheduleExactAlarms(),
      );
      _showSnackBar('Test notification scheduled for 10 seconds from now!');
    } catch (e) {
      _showSnackBar('Failed to schedule test notification: $e', Colors.red);
    }
  }

  /// Read once, before any await.
  ReminderSettings get _settings =>
      Provider.of<ReminderSettingsService?>(context, listen: false)?.settings ??
      ReminderSettings.defaults;

  Future<void> _debugNotificationScheduling() async {
    final settings = _settings;
    try {
      final notificationsEnabled =
          await NotificationService.areNotificationsEnabled();
      final exactAllowed = await NotificationService.canScheduleExactAlarms();
      final pending = await NotificationService.getPendingNotifications();
      final pendingIds = pending.map((n) => n.id).toSet();
      final plan = NotificationHelper.planReminders(
        widget.datesByType,
        settings: settings,
      );

      final debugInfo = <String>[
        '=== NOTIFICATION DEBUG INFO ===',
        'Notifications enabled: ${notificationsEnabled ? "yes" : "NO"}',
        'Exact alarms allowed: ${exactAllowed ? "yes" : "NO (inexact)"}',
        '',
        'Dates by type:',
        for (final type in TrashType.values)
          '- ${type.name}: ${widget.datesByType[type]!.length}',
        '',
        'Planned reminders: ${plan.length}',
        'Pending (plugin cache): ${pending.length}',
        'Missing from cache: '
            '${plan.where((r) => !pendingIds.contains(r.id)).length}',
        '',
        for (final reminder in plan.take(20)) ...[
          '${DateFormatHelper.formatDate(reminder.pickupDate)} '
              '(${reminder.type.name}):',
          '  Reminder: ${_formatDateTime(reminder.time)}',
          '  ID: ${reminder.id}'
              '${pendingIds.contains(reminder.id) ? "" : "  (NOT PENDING)"}',
          '',
        ],
        if (plan.length > 20) '... ${plan.length - 20} more',
      ];

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notification Debug'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 600),
            child: SingleChildScrollView(
              child: Text(
                debugInfo.join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _forceRescheduleAll();
              },
              child: const Text('Force Reschedule All'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showSnackBar('Debug failed: $e', Colors.red);
    }
  }

  Future<void> _forceRescheduleAll() async {
    final result = await widget.onReschedule?.call();
    if (result == null) {
      _showSnackBar('Failed to reschedule', Colors.red);
      return;
    }
    _showSnackBar(
      'Rescheduled ${result.scheduled} reminders'
      '${result.exact ? "" : " (inexact)"}'
      '${result.failed > 0 ? ", ${result.failed} failed" : ""}',
      result.failed > 0 ? Colors.orange : Colors.green,
    );
  }

  Future<void> _debugWidget() async {
    try {
      await WidgetService.updateWidget();
      _showSnackBar('Widget update triggered!');
    } catch (e) {
      _showSnackBar('Widget update failed: $e', Colors.red);
    }
  }

  Future<void> _showPendingNotifications() async {
    final settings = _settings;
    try {
      final pendingNotifications =
          await NotificationService.getPendingNotifications();

      if (!mounted) return;

      if (pendingNotifications.isEmpty) {
        _showSnackBar('No scheduled notifications found', Colors.orange);
        return;
      }

      final plannedById = {
        for (final reminder in NotificationHelper.planReminders(
          widget.datesByType,
          settings: settings,
        ))
          reminder.id: reminder,
      };
      pendingNotifications.sort((a, b) => a.id.compareTo(b.id));

      List<Widget> notificationWidgets = [];

      for (int i = 0; i < pendingNotifications.length; i++) {
        final notification = pendingNotifications[i];
        final reminder =
            plannedById[notification.id] ??
            NotificationHelper.decodeNotificationId(notification.id, settings);

        notificationWidgets.add(
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: reminder != null
                            ? TrashColors.getColorByType(reminder.type)
                            : Colors.grey,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification.title ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.body ?? 'No content',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _describeReminder(notification, reminder),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${notification.id}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled Notifications (${pendingNotifications.length})',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(children: notificationWidgets),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await NotificationService.cancelAllNotifications();
                  _showSnackBar('All notifications cancelled', Colors.red);
                },
                child: const Text(
                  'Cancel All',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      _showSnackBar('Failed to get pending notifications: $e', Colors.red);
    }
  }

  String _describeReminder(
    PendingNotificationRequest notification,
    PlannedReminder? reminder,
  ) {
    if (reminder == null) {
      return 'Scheduled notification (ID: ${notification.id})';
    }

    final collectionDate =
        '${DateFormatHelper.formatDayName(reminder.pickupDate)}, '
        '${DateFormatHelper.formatDate(reminder.pickupDate)}';
    var timingInfo = 'Reminder: ${_formatDateTime(reminder.time)}';

    final untilReminder = reminder.time.difference(DateTime.now());
    if (untilReminder.isNegative) {
      timingInfo += ' (Past due)';
    } else if (untilReminder.inHours < 1) {
      timingInfo += ' (in ${untilReminder.inMinutes}m)';
    } else if (untilReminder.inHours < 24) {
      timingInfo += ' (in ${untilReminder.inHours}h)';
    } else {
      timingInfo += ' (in ${untilReminder.inDays}d)';
    }

    return '$timingInfo\nFor collection: $collectionDate';
  }

  String _formatDateTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${DateFormatHelper.formatDayName(time)}, '
        '${DateFormatHelper.formatDate(time)} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }
}
