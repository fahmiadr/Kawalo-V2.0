import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/home/domain/entities/home_layout.dart';

void main() {
  test('visible keeps order and skips hidden cards', () {
    const layout = HomeLayout(
      order: [HomeCard.inc, HomeCard.sos, HomeCard.pat],
      hidden: {HomeCard.pat},
    );
    expect(layout.visible, [HomeCard.inc, HomeCard.sos]);
    expect(layout.isValid, isTrue);
  });

  test('complete appends missing cards as hidden', () {
    final complete = HomeLayout.fallback.complete;
    expect(complete.order, HomeCard.values.toList());
    expect(complete.hidden, {HomeCard.gst, HomeCard.sch});
    expect(complete.visible, HomeLayout.fallback.visible);
  });

  test('isValid mirrors the API rules', () {
    expect(
      const HomeLayout(order: [HomeCard.inc]).isValid,
      isFalse,
      reason: 'SOS missing',
    );
    expect(
      const HomeLayout(order: [HomeCard.sos], hidden: {HomeCard.sos}).isValid,
      isFalse,
      reason: 'SOS hidden',
    );
    expect(
      const HomeLayout(
        order: [
          HomeCard.ptt,
          HomeCard.sos,
          HomeCard.inc,
          HomeCard.pat,
          HomeCard.gst,
        ],
      ).isValid,
      isFalse,
      reason: 'five visible',
    );
  });

  test('fromKeys drops unknown keys and falls back when invalid', () {
    final layout = HomeLayout.fromKeys(
      order: const ['sos', 'radar', 'gst'],
      hidden: const ['radar'],
    );
    expect(layout.order, [HomeCard.sos, HomeCard.gst]);
    expect(layout.hidden, isEmpty);

    expect(
      HomeLayout.fromKeys(order: const ['inc'], hidden: const []),
      HomeLayout.fallback,
    );
  });
}
