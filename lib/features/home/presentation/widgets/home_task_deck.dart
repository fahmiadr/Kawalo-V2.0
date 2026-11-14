import 'package:flutter/material.dart';
import 'package:kawalo_mobile/core/theme/app_motion.dart';
import 'package:kawalo_mobile/core/theme/kawalo_tones.dart';

class HomeDeckPage {
  const HomeDeckPage({
    required this.id,
    required this.label,
    required this.icon,
    required this.tone,
    required this.child,
  });

  /// Stable across layout changes, so the open card survives a reorder.
  final String id;
  final String label;
  final IconData icon;
  final KawaloTone tone;
  final Widget child;
}

/// The Beranda: one task card per page with the neighbours peeking, arrow
/// buttons at the sides, and a bottom bar whose items are the same cards.
/// Swipe, arrows, bar and a tap on a peeking card all move the same index.
class HomeTaskDeck extends StatefulWidget {
  const HomeTaskDeck({required this.pages, super.key});

  final List<HomeDeckPage> pages;

  @override
  State<HomeTaskDeck> createState() => _HomeTaskDeckState();
}

class _HomeTaskDeckState extends State<HomeTaskDeck> {
  final _controller = PageController(viewportFraction: 0.9);
  int _index = 0;

  /// Until the user moves, a layout change (the saved layout arriving after
  /// the default) keeps the first card; afterwards the open card is kept.
  bool _touched = false;

  @override
  void didUpdateWidget(covariant HomeTaskDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_touched) return;
    final oldId = _index < oldWidget.pages.length
        ? oldWidget.pages[_index].id
        : null;
    final kept = widget.pages.indexWhere((p) => p.id == oldId);
    final next = kept >= 0 ? kept : _index.clamp(0, widget.pages.length - 1);
    if (next != _index) {
      _index = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToPage(_index);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int index) {
    if (index == _index || !_controller.hasClients) return;
    _touched = true;
    setState(() => _index = index);
    if (AppMotion.isReducedMotion(context)) {
      _controller.jumpToPage(index);
    } else {
      _controller.animateToPage(
        index,
        duration: AppMotion.medium2,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final pages = widget.pages;

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() {
                  _touched = true;
                  _index = i;
                }),
                itemBuilder: (context, i) {
                  final isCurrent = i == _index;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isCurrent ? null : () => _go(i),
                    child: ExcludeSemantics(
                      excluding: !isCurrent,
                      child: AbsorbPointer(
                        absorbing: !isCurrent,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 10,
                          ),
                          padding: const EdgeInsets.all(18),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: tones.surface,
                            border: Border.all(color: tones.line),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: pages[i].child,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_index > 0)
                _Arrow(
                  left: true,
                  label: 'Kartu sebelumnya: ${pages[_index - 1].label}',
                  onTap: () => _go(_index - 1),
                ),
              if (_index < pages.length - 1)
                _Arrow(
                  left: false,
                  label: 'Kartu berikutnya: ${pages[_index + 1].label}',
                  onTap: () => _go(_index + 1),
                ),
            ],
          ),
        ),
        Container(
          color: tones.background,
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 6),
          child: Row(
            children: [
              for (var i = 0; i < pages.length; i++)
                Expanded(
                  child: _BarItem(
                    page: pages[i],
                    selected: i == _index,
                    onTap: () => _go(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.left, required this.label, required this.onTap});

  final bool left;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    return Positioned(
      left: left ? 2 : null,
      right: left ? null : 2,
      top: 0,
      bottom: 0,
      child: Center(
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: tones.surface,
            shape: CircleBorder(side: BorderSide(color: tones.line)),
            elevation: 3,
            shadowColor: Colors.black38,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  left
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: tones.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final HomeDeckPage page;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = KawaloTones.of(context);
    final color = selected ? page.tone.color : tones.ink2;
    return Semantics(
      button: true,
      selected: selected,
      label: page.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.short4,
                width: 54,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? page.tone.soft : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(page.icon, size: 22, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                page.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
