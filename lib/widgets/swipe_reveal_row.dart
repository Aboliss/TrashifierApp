import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// A row that slides right to reveal an action button behind its left edge,
/// e.g. Remove.
///
/// Only rightward drags (or leftward ones while open) are claimed, so a left
/// swipe still reaches the surrounding PageView. Only one row in a
/// [SwipeRevealGroup] is open at a time.
class SwipeRevealRow extends StatefulWidget {
  final Widget child;

  /// The button revealed behind the row, sized [actionWidth] wide.
  final Widget action;
  final double actionWidth;

  /// Read out by screen readers in place of the swipe.
  final String actionLabel;
  final VoidCallback onAction;

  final BorderRadius borderRadius;

  const SwipeRevealRow({
    super.key,
    required this.child,
    required this.action,
    required this.actionLabel,
    required this.onAction,
    this.actionWidth = 96,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<SwipeRevealRow> createState() => _SwipeRevealRowState();
}

class _SwipeRevealRowState extends State<SwipeRevealRow>
    with SingleTickerProviderStateMixin {
  // 0 = closed, 1 = action fully revealed.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  SwipeRevealGroup? _group;

  bool get _isOpen => _reveal.value > 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = SwipeRevealGroup.maybeOf(context);
    if (group != _group) {
      _group?.openRow.removeListener(_onGroupChanged);
      _group = group?..openRow.addListener(_onGroupChanged);
    }
  }

  @override
  void dispose() {
    _group?.openRow.removeListener(_onGroupChanged);
    _reveal.dispose();
    super.dispose();
  }

  void _onGroupChanged() {
    if (_group?.openRow.value != this && _isOpen) _close();
  }

  void _open() {
    _reveal.animateTo(1, curve: Curves.easeOutCubic);
    _group?.openRow.value = this;
  }

  void _close() {
    _reveal.animateTo(0, curve: Curves.easeOutCubic);
    if (_group?.openRow.value == this) _group?.openRow.value = null;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _reveal.value += details.primaryDelta! / widget.actionWidth;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 300 || (velocity > -300 && _reveal.value > 0.5)) {
      _open();
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: widget.actionLabel): widget.onAction,
      },
      child: RawGestureDetector(
        gestures: {
          _RightwardDragRecognizer:
              GestureRecognizerFactoryWithHandlers<_RightwardDragRecognizer>(
                () => _RightwardDragRecognizer(allowLeft: () => _isOpen),
                (recognizer) => recognizer
                  // The device's touch slop, like the surrounding PageView.
                  ..gestureSettings = gestureSettings
                  ..onUpdate = _onDragUpdate
                  ..onEnd = _onDragEnd,
              ),
        },
        child: ClipRRect(
          borderRadius: widget.borderRadius,
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: widget.actionWidth,
                    child: ExcludeSemantics(
                      child: GestureDetector(
                        onTap: () {
                          _close();
                          widget.onAction();
                        },
                        child: widget.action,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _reveal,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_reveal.value * widget.actionWidth, 0),
                  child: child,
                ),
                // Tapping the open row closes it instead of doing anything.
                child: GestureDetector(
                  onTap: () {
                    if (_isOpen) _close();
                  },
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lets rows close each other: opening one closes the open one.
class SwipeRevealGroup extends InheritedWidget {
  final ValueNotifier<Object?> openRow;

  const SwipeRevealGroup({
    super.key,
    required this.openRow,
    required super.child,
  });

  static SwipeRevealGroup? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SwipeRevealGroup>();

  @override
  bool updateShouldNotify(SwipeRevealGroup oldWidget) =>
      openRow != oldWidget.openRow;
}

/// Claims horizontal drags that start rightward; leftward ones only when
/// [allowLeft] says so (the row is open and can be pushed closed).
///
/// Accepts a little before the usual touch slop: the surrounding PageView
/// uses that slop and, reached first, would win every rightward drag (on
/// Android the device slop is smaller than Flutter's default, so a row that
/// used the default lost from the second swipe on).
class _RightwardDragRecognizer extends HorizontalDragGestureRecognizer {
  static const double _slopFactor = 0.8;

  final bool Function() allowLeft;

  _RightwardDragRecognizer({required this.allowLeft});

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    final slop =
        computeHitSlop(pointerDeviceKind, gestureSettings) * _slopFactor;
    return globalDistanceMoved > slop ||
        (allowLeft() && globalDistanceMoved < -slop);
  }
}
