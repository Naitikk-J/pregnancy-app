import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/dashboard/data/daily_content.dart';

void main() {
  group('DailyContent', () {
    test('quote is stable within the same day', () {
      final a = DailyContent.quoteFor(DateTime(2026, 3, 15, 8));
      final b = DailyContent.quoteFor(DateTime(2026, 3, 15, 21));
      expect(a, b);
    });

    test('quote changes across consecutive days (given list length)', () {
      final d1 = DailyContent.quoteFor(DateTime(2026, 3, 15));
      final d2 = DailyContent.quoteFor(DateTime(2026, 3, 16));
      expect(d1, isNot(equals(d2)));
    });

    test('always returns a non-empty item within range', () {
      for (var i = 0; i < 400; i++) {
        final date = DateTime(2026).add(Duration(days: i));
        expect(DailyContent.quoteFor(date), isNotEmpty);
        expect(DailyContent.nutritionTipFor(date), isNotEmpty);
        expect(DailyContent.dailyFocusFor(date), isNotEmpty);
        expect(DailyContent.smileFor(date), isNotEmpty);
      }
    });

    test('daily focus and smile are stable within a day', () {
      final morning = DateTime(2026, 6, 1, 7);
      final evening = DateTime(2026, 6, 1, 22);
      expect(DailyContent.dailyFocusFor(morning),
          DailyContent.dailyFocusFor(evening));
      expect(DailyContent.smileFor(morning), DailyContent.smileFor(evening));
    });
  });
}
