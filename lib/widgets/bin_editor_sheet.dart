import 'package:flutter/material.dart';
import 'package:trashifier_app/config/app_theme.dart';
import 'package:trashifier_app/helpers/trash_type_helper.dart';
import 'package:trashifier_app/l10n/l10n.dart';
import 'package:trashifier_app/models/bin_style.dart';
import 'package:trashifier_app/models/trash_type.dart';
import 'package:trashifier_app/widgets/bin_badges.dart';
import 'package:trashifier_app/widgets/bin_icon.dart';

/// What the bin editor asks for.
sealed class BinEdit {
  const BinEdit();
}

/// Save the bin with these values; a null [name] brings back a built-in's
/// own name.
class BinSave extends BinEdit {
  final String? name;
  final int color;
  final int icon;

  const BinSave({required this.name, required this.color, required this.icon});
}

/// Delete the (custom) bin; the caller confirms first.
class BinDelete extends BinEdit {
  const BinDelete();
}

/// Adds a bin, or edits [bin]: name, color and icon, plus Delete for custom
/// bins.
class BinEditorSheet extends StatefulWidget {
  /// Null for a new bin.
  final TrashType? bin;

  const BinEditorSheet({super.key, this.bin});

  static Future<BinEdit?> show(BuildContext context, {TrashType? bin}) {
    return showModalBottomSheet<BinEdit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BinEditorSheet(bin: bin),
    );
  }

  @override
  State<BinEditorSheet> createState() => _BinEditorSheetState();
}

class _BinEditorSheetState extends State<BinEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.bin?.customName ?? '',
  );
  // A new bin starts on the first color and icon past the built-ins'.
  late int _color = widget.bin?.color ?? 4;
  late int _icon = widget.bin?.icon ?? 4;

  bool get _isNew => widget.bin == null;
  bool get _isBuiltIn => widget.bin?.isBuiltIn ?? false;

  /// The built-in's own (translated) name, shown when the field is empty.
  String? get _defaultName => _isBuiltIn
      ? TrashTypeHelper.getDisplayName(
          widget.bin!.copyWith(clearCustomName: true),
        )
      : null;

  String? get _cleanName => TrashType.cleanName(_name.text);

  bool get _canSave => _isBuiltIn || _cleanName != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// The bin as it will look, for the preview tile.
  TrashType get _preview =>
      (widget.bin ??
              const TrashType(
                id: 'cpreview',
                slot: TrashType.maxBins - 1,
                position: 0,
                color: 4,
                icon: 4,
              ))
          .copyWith(color: _color, icon: _icon);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l = context.l10n;
    final title = _cleanName ?? _defaultName ?? l.addBin;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 18,
        children: [
          Row(
            spacing: 14,
            children: [
              BinIconTile(_preview, size: 56),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      _isNew ? l.newBinEyebrow : l.editBinEyebrow,
                      style: AppFonts.eyebrow(palette.muted),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.headline(26, palette.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
          TextField(
            controller: _name,
            autofocus: _isNew,
            maxLength: TrashType.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l.binName,
              hintText: _defaultName ?? l.binNameHint,
              helperText: _defaultName == null
                  ? null
                  : l.binNameDefault(_defaultName!),
              filled: true,
              fillColor: palette.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.line, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.line, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: palette.ink, width: 2),
              ),
            ),
          ),
          _Label(l.binColor),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < BinStyle.colors.length; i++)
                _ColorSwatch(
                  color: context.isDark
                      ? BinStyle.colors[i].darkMode
                      : BinStyle.colors[i].base,
                  selected: i == _color,
                  label: l.binColorA11y(i + 1),
                  onTap: () => setState(() => _color = i),
                ),
            ],
          ),
          _Label(l.binIcon),
          GridView.count(
            crossAxisCount: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < BinStyle.icons.length; i++)
                _IconChoice(
                  bin: _preview.copyWith(icon: i),
                  selected: i == _icon,
                  label: l.binIconA11y(i + 1),
                  onTap: () => setState(() => _icon = i),
                ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: PillButton(
                  label: l.cancel,
                  outlined: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                flex: 2,
                child: PillButton(
                  label: _isNew ? l.addBinButton : l.save,
                  onPressed: _canSave
                      ? () => Navigator.pop(
                          context,
                          BinSave(name: _cleanName, color: _color, icon: _icon),
                        )
                      : null,
                ),
              ),
            ],
          ),
          if (!_isNew && !_isBuiltIn)
            TextButton.icon(
              onPressed: () => Navigator.pop(context, const BinDelete()),
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(l.deleteBin),
              style: TextButton.styleFrom(
                foregroundColor: context.isDark
                    ? const Color(0xFFFF8A75)
                    : const Color(0xFFC2412D),
                minimumSize: const Size.fromHeight(44),
              ),
            ),
        ],
      ),
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

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? palette.ink : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.ground, width: 2),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  final TrashType bin;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _IconChoice({
    required this.bin,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? palette.card : palette.chip,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? palette.ink : Colors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: BinIcon(bin, color: palette.ink, size: 20)),
        ),
      ),
    );
  }
}
