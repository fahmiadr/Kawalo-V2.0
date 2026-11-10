import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/information/presentation/cubit/information_form_photos.dart';
import 'package:kawalo_mobile/features/information/presentation/models/information_form_media_item.dart';

InformationFormMediaItem local(String id, {String? path}) =>
    InformationFormMediaItem(id: id, name: '$id.jpg', path: path ?? '/p/$id');

InformationFormMediaItem remote(String url) =>
    InformationFormMediaItem.fromRemoteUrl(url);

List<String> ids(List<InformationFormMediaItem> items) =>
    items.map((e) => e.id).toList();

void main() {
  group('InformationFormPhotos.isSameMedia', () {
    test('matches by path or remote url', () {
      expect(
        InformationFormPhotos.isSameMedia(
          local('a', path: '/x'),
          local('b', path: '/x'),
        ),
        isTrue,
      );
      expect(
        InformationFormPhotos.isSameMedia(
          remote('https://x/a.jpg'),
          remote('https://x/a.jpg'),
        ),
        isTrue,
      );
      expect(
        InformationFormPhotos.isSameMedia(local('a'), local('b')),
        isFalse,
      );
    });

    test('never matches items that are still loading', () {
      final loading = InformationFormMediaItem.loading(id: 'l');
      expect(InformationFormPhotos.isSameMedia(loading, loading), isFalse);
    });
  });

  group('InformationFormPhotos.planAdd', () {
    test('adds new items in order', () {
      final plan = InformationFormPhotos.planAdd(
        [local('a')],
        [local('b'), local('c')],
        maxPhotos: 4,
      );
      expect(plan.error, isNull);
      expect(ids(plan.added), ['b', 'c']);
    });

    test('trims to the remaining slots', () {
      final plan = InformationFormPhotos.planAdd(
        [local('a'), local('b'), local('c')],
        [local('d'), local('e')],
        maxPhotos: 4,
      );
      expect(ids(plan.added), ['d']);
    });

    test('rejects when the limit is already reached', () {
      final plan = InformationFormPhotos.planAdd(
        [local('a'), local('b')],
        [local('c')],
        maxPhotos: 2,
      );
      expect(plan.added, isEmpty);
      expect(plan.error, 'Maksimal 2 foto dapat dilampirkan.');
    });

    test('skips duplicates against current and within the batch', () {
      final plan = InformationFormPhotos.planAdd(
        [local('a')],
        [local('a2', path: '/p/a'), local('b'), local('b2', path: '/p/b')],
        maxPhotos: 4,
      );
      expect(ids(plan.added), ['b']);
    });

    test('reports duplicates with single or batch wording', () {
      final single = InformationFormPhotos.planAdd(
        [local('a')],
        [local('x', path: '/p/a')],
        maxPhotos: 4,
      );
      expect(single.error, 'Foto tersebut sudah ada dalam lampiran.');

      final batch = InformationFormPhotos.planAdd(
        [local('a')],
        [local('x', path: '/p/a'), local('y', path: '/p/a')],
        maxPhotos: 4,
      );
      expect(batch.error, 'Foto yang dipilih sudah ada dalam lampiran.');
    });

    test('loading placeholders are never treated as duplicates', () {
      final plan = InformationFormPhotos.planAdd(
        [InformationFormMediaItem.loading(id: 'l1')],
        [InformationFormMediaItem.loading(id: 'l2')],
        maxPhotos: 4,
      );
      expect(ids(plan.added), ['l2']);
    });
  });

  group('InformationFormPhotos list edits', () {
    final current = [local('a'), local('b'), local('c')];

    test('replaceById swaps the matching item without mutating input', () {
      final updated = InformationFormPhotos.replaceById(
        current,
        'b',
        local('z'),
      );
      expect(ids(updated!), ['a', 'z', 'c']);
      expect(ids(current), ['a', 'b', 'c']);
      expect(
        InformationFormPhotos.replaceById(current, 'nope', local('z')),
        isNull,
      );
    });

    test('removeAt drops the item and rejects out-of-range indexes', () {
      expect(ids(InformationFormPhotos.removeAt(current, 1)!), ['a', 'c']);
      expect(InformationFormPhotos.removeAt(current, -1), isNull);
      expect(InformationFormPhotos.removeAt(current, 3), isNull);
      expect(ids(current), ['a', 'b', 'c']);
    });

    test('reorder moves an item and rejects invalid moves', () {
      expect(ids(InformationFormPhotos.reorder(current, 0, 2)!), [
        'b',
        'c',
        'a',
      ]);
      expect(ids(InformationFormPhotos.reorder(current, 2, 0)!), [
        'c',
        'a',
        'b',
      ]);
      expect(InformationFormPhotos.reorder(current, 1, 1), isNull);
      expect(InformationFormPhotos.reorder(current, -1, 1), isNull);
      expect(InformationFormPhotos.reorder(current, 0, 3), isNull);
      expect(ids(current), ['a', 'b', 'c']);
    });
  });

  group('InformationFormPhotos.payloadUrls', () {
    test('keeps only hosted urls and never invents one for local files', () {
      final urls = InformationFormPhotos.payloadUrls([
        local('a'),
        local('b').copyWith(remoteUrl: 'https://cdn.test/b.webp'),
        remote('https://x/c.jpg'),
      ]);
      expect(urls, ['https://cdn.test/b.webp', 'https://x/c.jpg']);
    });
  });

  group('InformationFormPhotos.validate', () {
    test('flags over-limit lists before loading items', () {
      expect(
        InformationFormPhotos.validate([
          local('a'),
          local('b'),
          InformationFormMediaItem.loading(),
        ], maxPhotos: 2),
        'Maksimal 2 foto dapat dilampirkan.',
      );
    });

    test('flags items still being processed', () {
      expect(
        InformationFormPhotos.validate([
          local('a'),
          InformationFormMediaItem.loading(),
        ], maxPhotos: 4),
        'Tunggu hingga semua foto selesai diproses.',
      );
    });

    test('accepts a settled list within the limit', () {
      expect(
        InformationFormPhotos.validate([local('a')], maxPhotos: 4),
        isNull,
      );
    });
  });
}
