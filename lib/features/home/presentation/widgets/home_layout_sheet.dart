import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';
import 'package:kawalo_mobile/core/widgets/app_bottom_sheet.dart';
import 'package:kawalo_mobile/core/widgets/app_snackbar.dart';
import 'package:kawalo_mobile/core/widgets/app_task_button.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';
import 'package:kawalo_mobile/features/home/presentation/extensions/home_card_ui_extension.dart';

/// "Atur Beranda": reorder with up/down, show/hide with a switch, at most
/// [HomeLayout.maxVisible] cards shown, SOS always shown. "Lainnya" is not
/// listed: it is fixed as the last card. Pops with the new layout on
/// "Simpan", null otherwise.
class HomeLayoutSheet extends StatefulWidget {
  const HomeLayoutSheet({
    required this.layout,
    required this.showPtt,
    super.key,
  });

  final HomeLayout layout;

  /// False where PTT is not supported (iOS): the row is not listed and PTT is
  /// saved hidden, so it never takes one of the four visible slots there.
  final bool showPtt;

  static Future<HomeLayout?> show(
    BuildContext context, {
    required HomeLayout layout,
    required bool showPtt,
  }) => showAppBottomSheet<HomeLayout>(
    context: context,
    maxHeightFactor: 0.9,
    child: HomeLayoutSheet(layout: layout, showPtt: showPtt),
  );

  @override
  State<HomeLayoutSheet> createState() => _HomeLayoutSheetState();
}

class _HomeLayoutSheetState extends State<HomeLayoutSheet> {
  late List<HomeCard> _order;
  late Set<HomeCard> _hidden;

  @override
  void initState() {
    super.initState();
    _reset(widget.layout);
  }

  void _reset(HomeLayout layout) {
    final complete = layout.complete;
    _order = [...complete.order];
    _hidden = {...complete.hidden, if (!widget.showPtt) HomeCard.ptt};
  }

  List<HomeCard> get _rows => [
    for (final card in _order)
      if (widget.showPtt || card != HomeCard.ptt) card,
  ];

  int get _visibleCount => _order.where((c) => !_hidden.contains(c)).length;

  void _move(HomeCard card, int delta) {
    final rows = _rows;
    final target = rows.indexOf(card) + delta;
    if (target < 0 || target >= rows.length) return;
    final other = rows[target];
    setState(() {
      final a = _order.indexOf(card);
      final b = _order.indexOf(other);
      _order[a] = other;
      _order[b] = card;
    });
  }

  void _toggle(HomeCard card, bool show) {
    if (show && _visibleCount >= HomeLayout.maxVisible) {
      AppSnackbar.show(
        context,
        message: 'Maksimal 4 kartu tugas. Sembunyikan kartu lain dulu.',
      );
      return;
    }
    setState(() => show ? _hidden.remove(card) : _hidden.add(card));
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final rows = _rows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Atur Beranda',
            style: TextStyle(
              color: tones.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Urutan di sini sama dengan bar bawah. $_visibleCount dari '
            '${HomeLayout.maxVisible} kartu tugas tampil.',
            style: TextStyle(color: tones.ink2, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _Row(
                      card: rows[i],
                      shown: !_hidden.contains(rows[i]),
                      canUp: i > 0,
                      canDown: i < rows.length - 1,
                      onUp: () => _move(rows[i], -1),
                      onDown: () => _move(rows[i], 1),
                      onToggle: rows[i] == HomeCard.sos
                          ? null
                          : (v) => _toggle(rows[i], v),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTaskButton(
                  label: 'Kembalikan bawaan',
                  variant: AppTaskButtonVariant.secondary,
                  size: AppTaskButtonSize.medium,
                  onPressed: () => setState(() => _reset(HomeLayout.fallback)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTaskButton(
                  label: 'Simpan',
                  size: AppTaskButtonSize.medium,
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(HomeLayout(order: [..._order], hidden: {..._hidden})),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.card,
    required this.shown,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.onToggle,
  });

  final HomeCard card;
  final bool shown;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;

  /// Null for SOS, which cannot be hidden.
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final tone = card.tone(tones);

    Widget move(
      IconData icon,
      String label,
      VoidCallback tap, {
      required bool enabled,
    }) => Semantics(
      button: true,
      enabled: enabled,
      label: '$label ${card.label}',
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: tones.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? tap : null,
            child: SizedBox.square(
              dimension: 44,
              child: Icon(icon, color: tones.ink),
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tones.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.soft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(card.icon, color: tone.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.label,
                  style: TextStyle(
                    color: tones.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  card.description,
                  style: TextStyle(color: tones.ink2, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          move(
            Icons.keyboard_arrow_up_rounded,
            'Naikkan',
            onUp,
            enabled: canUp,
          ),
          const SizedBox(width: 4),
          move(
            Icons.keyboard_arrow_down_rounded,
            'Turunkan',
            onDown,
            enabled: canDown,
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Tampilkan ${card.label}',
            child: Switch(
              value: shown,
              activeTrackColor: tones.ptt.color,
              activeThumbColor: tones.ptt.on,
              onChanged: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}
