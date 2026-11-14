import 'package:equatable/equatable.dart';

/// A task card the user can place on the Beranda. The enum name is the wire
/// key of `/me/home-layout`. "Lainnya" is not one of them: it is always shown,
/// always last.
enum HomeCard { ptt, sos, inc, pat, gst, sch }

/// Which task cards the Beranda shows and in which order, per user per group.
class HomeLayout extends Equatable {
  const HomeLayout({
    required this.order,
    this.hidden = const {},
    this.isDefault = false,
  });

  /// Unknown keys (a newer server) are dropped; an invalid result falls back
  /// to [fallback] so the Beranda always has SOS.
  factory HomeLayout.fromKeys({
    required List<String> order,
    required List<String> hidden,
    bool isDefault = false,
  }) {
    HomeCard? parse(String key) =>
        HomeCard.values.where((c) => c.name == key).firstOrNull;
    final layout = HomeLayout(
      order: order.map(parse).nonNulls.toSet().toList(),
      hidden: hidden.map(parse).nonNulls.toSet(),
      isDefault: isDefault,
    );
    return layout.isValid ? layout : fallback;
  }

  /// Server default when nothing is saved.
  static const fallback = HomeLayout(
    order: [HomeCard.ptt, HomeCard.sos, HomeCard.inc, HomeCard.pat],
    isDefault: true,
  );

  /// Visible task cards plus "Lainnya" fill the five bottom-bar slots.
  static const maxVisible = 4;

  final List<HomeCard> order;
  final Set<HomeCard> hidden;
  final bool isDefault;

  List<HomeCard> get visible => [
    for (final card in order)
      if (!hidden.contains(card)) card,
  ];

  /// Every card exactly once: the saved order first, cards missing from it
  /// appended as hidden. This is what the "Atur Beranda" editor lists.
  HomeLayout get complete {
    final missing = HomeCard.values.where((c) => !order.contains(c));
    return HomeLayout(
      order: [...order, ...missing],
      hidden: {...hidden, ...missing},
      isDefault: isDefault,
    );
  }

  /// Mirrors the API's 422 rules: SOS present and shown, 1..[maxVisible]
  /// visible, keys unique.
  bool get isValid =>
      order.toSet().length == order.length &&
      order.contains(HomeCard.sos) &&
      !hidden.contains(HomeCard.sos) &&
      visible.isNotEmpty &&
      visible.length <= maxVisible;

  @override
  List<Object?> get props => [order, hidden, isDefault];
}
