import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/l10n/l10n.dart';

/// Small pill telling first-time users they can swipe to the calendar, with
/// a chevron that nudges left a few times, then rests.
class SwipeHint extends StatefulWidget {
  const SwipeHint({super.key});

  @override
  State<SwipeHint> createState() => _SwipeHintState();
}

class _SwipeHintState extends State<SwipeHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(count: 4);

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: palette.ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0A140F),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          AnimatedBuilder(
            animation: _nudge,
            builder: (context, child) {
              // Quick slide left, then rest: 0 -> -6 px -> 0.
              final t = Curves.easeInOut.transform(
                (_nudge.value * 2).clamp(0.0, 1.0),
              );
              final dx = -6 * (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Icon(
              Icons.keyboard_double_arrow_left_rounded,
              size: 18,
              color: palette.ground,
            ),
          ),
          Flexible(
            child: Text(
              context.l10n.swipeHint,
              style: TextStyle(
                color: palette.ground,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
