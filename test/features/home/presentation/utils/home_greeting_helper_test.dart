import 'package:flutter_test/flutter_test.dart';
import 'package:kawalo_mobile/features/home/presentation/utils/home_greeting_helper.dart';

void main() {
  group('HomeGreetingHelper Tests', () {
    test('getTimeOfDayGreeting returns correct greetings according to '
        'Indonesian cultural standard', () {
      // Pagi: 05:00 - 10:59
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 5)),
        equals('Selamat pagi'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 8, 30)),
        equals('Selamat pagi'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 10, 59)),
        equals('Selamat pagi'),
      );

      // Siang: 11:00 - 14:59
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 11)),
        equals('Selamat siang'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 13, 15)),
        equals('Selamat siang'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 14, 59)),
        equals('Selamat siang'),
      );

      // Sore: 15:00 - 17:59
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 15)),
        equals('Selamat sore'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 16, 45)),
        equals('Selamat sore'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 17, 59)),
        equals('Selamat sore'),
      );

      // Malam: 18:00 - 04:59 (termasuk tengah malam dan dini hari)
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 18)),
        equals('Selamat malam'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 21)),
        equals('Selamat malam'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 23, 59)),
        equals('Selamat malam'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2)),
        equals('Selamat malam'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 3, 30)),
        equals('Selamat malam'),
      );
      expect(
        HomeGreetingHelper.getTimeOfDayGreeting(DateTime(2026, 9, 2, 4, 59)),
        equals('Selamat malam'),
      );
    });

    test('formatGreeting formats user with role and name', () {
      final greeting = HomeGreetingHelper.formatGreeting(
        name: 'AHMAD ZAKI FAUZAN',
        role: 'admin',
        dateTime: DateTime(2026, 9, 2, 12),
      );

      expect(greeting, equals('Selamat siang, admin AHMAD ZAKI FAUZAN!'));
    });

    test('formatGreeting formats user without role properly', () {
      final greeting = HomeGreetingHelper.formatGreeting(
        name: 'Budi Santoso',
        role: '',
        dateTime: DateTime(2026, 9, 2, 8),
      );

      expect(greeting, equals('Selamat pagi, BUDI SANTOSO!'));
    });

    test(
      'formatGreeting falls back to Personil when name is null or empty',
      () {
        final greeting = HomeGreetingHelper.formatGreeting(
          dateTime: DateTime(2026, 9, 2, 19),
        );

        expect(greeting, equals('Selamat malam, Personil!'));
      },
    );
  });
}
