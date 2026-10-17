import 'dart:async';

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

  /// Fills the whole area behind the row while it is swiped, so its rounded
  /// corners and the gap past the button show this color, not the page.
  final Color actionBackground;

  /// Read out by screen readers in place of the swipe.
  final String actionLabel;
  final VoidCallback onAction;

  final BorderRadius borderRadius;

  /// Slides the row part way open and back once, to show the action is
  /// there. It waits until the row is on screen, clear of [peekBottomInset]
  /// (e.g. a floating navigation bar), then runs [onPeeked]. Skipped when
  /// the platform asks for reduced motion.
  final bool peek;
  final VoidCallback? onPeeked;
  final double peekBottomInset;

  static const Duration peekDelay = Duration(seconds: 1);

  const SwipeRevealRow({
    super.key,
    required this.child,
    required this.action,
    required this.actionLabel,
    required this.onAction,
    required this.actionBackground,
    this.actionWidth = 96,
    this.borderRadius = BorderRadius.zero,
    this.peek = false,
    this.onPeeked,
    this.peekBottomInset = 0,
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

  Timer? _peekTimer;
  bool _peeking = false;

  bool get _isOpen => _reveal.value > 0;

  @override
  void initState() {
    super.initState();
    _schedulePeek();
  }

  @override
  void didUpdateWidget(SwipeRevealRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.peek && !oldWidget.peek) _schedulePeek();
    if (!widget.peek) _peekTimer?.cancel();
  }

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
    _peekTimer?.cancel();
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

  void _schedulePeek() {
    if (!widget.peek) return;
    _peekTimer?.cancel();
    _peekTimer = Timer(SwipeRevealRow.peekDelay, _tryPeek);
  }

  /// Peeks if the row can be seen, else checks again a little later.
  void _tryPeek() {
    if (!mounted || !widget.peek || _peeking) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    if (_isOpen || !TickerMode.of(context) || !_onScreen()) {
      _schedulePeek();
      return;
    }
    _runPeek();
  }

  bool _onScreen() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    final screen = MediaQuery.sizeOf(context).height;
    return top >= 0 && bottom <= screen - widget.peekBottomInset;
  }

  Future<void> _runPeek() async {
    _peeking = true;
    try {
      await _reveal
          .animateTo(
            0.8,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          )
          .orCancel;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted || !_peeking) return;
      await _reveal
          .animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOutCubic,
          )
          .orCancel;
    } on TickerCanceled {
      // A drag or tap took over; that counts as seen too (below).
    } finally {
      _finishPeek();
    }
  }

  void _finishPeek() {
    if (!_peeking) return;
    _peeking = false;
    if (mounted) widget.onPeeked?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_peeking) {
      _reveal.stop();
      _finishPeek();
    }
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
              // Hidden while closed, or it would peek out of the row's
              // rounded corners.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) => ColoredBox(
                    color: _isOpen
                        ? widget.actionBackground
                        : Colors.transparent,
                  ),
                ),
              ),
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
