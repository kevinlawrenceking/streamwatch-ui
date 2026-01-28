import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/features/upload/views/upload_view.dart';

void main() {
  group('parseCelebrityInput', () {
    test('parses comma-separated names', () {
      final result = parseCelebrityInput('Kim Kardashian, Pete Davidson', []);

      expect(result.added, ['Kim Kardashian', 'Pete Davidson']);
      expect(result.duplicates, isEmpty);
    });

    test('parses newline-separated names', () {
      final result = parseCelebrityInput('Kim Kardashian\nPete Davidson', []);

      expect(result.added, ['Kim Kardashian', 'Pete Davidson']);
      expect(result.duplicates, isEmpty);
    });

    test('parses mixed comma and newline separators', () {
      final result =
          parseCelebrityInput('Kim Kardashian, Pete Davidson\nKanye West', []);

      expect(result.added, ['Kim Kardashian', 'Pete Davidson', 'Kanye West']);
      expect(result.duplicates, isEmpty);
    });

    test('ignores empty entries', () {
      final result = parseCelebrityInput('Kim Kardashian, , Pete Davidson', []);

      expect(result.added, ['Kim Kardashian', 'Pete Davidson']);
      expect(result.duplicates, isEmpty);
    });

    test('trims whitespace from names', () {
      final result =
          parseCelebrityInput('  Kim Kardashian  ,  Pete Davidson  ', []);

      expect(result.added, ['Kim Kardashian', 'Pete Davidson']);
    });

    test('detects case-insensitive duplicates against existing', () {
      final result = parseCelebrityInput('kim kardashian', ['Kim Kardashian']);

      expect(result.added, isEmpty);
      expect(result.duplicates, ['kim kardashian']);
    });

    test('detects case-insensitive duplicates within same input', () {
      final result =
          parseCelebrityInput('Kim Kardashian, kim kardashian, KIM KARDASHIAN', []);

      expect(result.added, ['Kim Kardashian']);
      expect(result.duplicates, ['kim kardashian', 'KIM KARDASHIAN']);
    });

    test('preserves first-seen casing', () {
      final result = parseCelebrityInput('kim kardashian', []);

      expect(result.added, ['kim kardashian']);
    });

    test('handles empty input', () {
      final result = parseCelebrityInput('', []);

      expect(result.added, isEmpty);
      expect(result.duplicates, isEmpty);
    });

    test('handles whitespace-only input', () {
      final result = parseCelebrityInput('   \n  ,  ', []);

      expect(result.added, isEmpty);
      expect(result.duplicates, isEmpty);
    });

    test('handles paste of multi-line text', () {
      final pastedText = '''Kim Kardashian
Pete Davidson
Kanye West, Taylor Swift''';

      final result = parseCelebrityInput(pastedText, []);

      expect(result.added,
          ['Kim Kardashian', 'Pete Davidson', 'Kanye West', 'Taylor Swift']);
    });

    test('correctly identifies new vs duplicate in mixed input', () {
      final result =
          parseCelebrityInput('Kim Kardashian, Pete Davidson, New Person', [
        'Kim Kardashian',
        'Existing Person',
      ]);

      expect(result.added, ['Pete Davidson', 'New Person']);
      expect(result.duplicates, ['Kim Kardashian']);
    });
  });
}
