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

    test('formatShort uses the time word and the first name', () {
      expect(
        HomeGreetingHelper.formatShort(
          name: 'BUDI SANTOSO',
          dateTime: DateTime(2026, 9, 2, 8),
        ),
        'Pagi, Budi',
      );
      expect(
        HomeGreetingHelper.formatShort(
          name: '  rina wati ',
          dateTime: DateTime(2026, 9, 2, 19),
        ),
        'Malam, Rina',
      );
    });

    test('formatShort without a name keeps the full greeting', () {
      expect(
        HomeGreetingHelper.formatShort(dateTime: DateTime(2026, 9, 2, 12)),
        'Selamat siang',
      );
      expect(
        HomeGreetingHelper.formatShort(
          name: ' ',
          dateTime: DateTime(2026, 9, 2, 16),
        ),
        'Selamat sore',
      );
    });
  });
}
