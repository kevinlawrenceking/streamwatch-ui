import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/data/models/celebrity_model.dart';

void main() {
  group('CelebrityModel', () {
    group('fromJson', () {
      test('parses complete celebrity data', () {
        final json = {
          'name': 'Kim Kardashian',
          'confidence': 0.95,
          'recognition_source': 'gemini_grounding',
        };

        final celebrity = CelebrityModel.fromJson(json);

        expect(celebrity.name, 'Kim Kardashian');
        expect(celebrity.confidence, 0.95);
        expect(celebrity.recognitionSource, 'gemini_grounding');
      });

      test('parses with full_name fallback', () {
        final json = {
          'full_name': 'Khloe Kardashian',
          'confidence': 0.88,
        };

        final celebrity = CelebrityModel.fromJson(json);

        expect(celebrity.name, 'Khloe Kardashian');
        expect(celebrity.confidence, 0.88);
        expect(celebrity.recognitionSource, isNull);
      });

      test('parses with label fallback', () {
        final json = {
          'label': 'Kourtney Kardashian',
        };

        final celebrity = CelebrityModel.fromJson(json);

        expect(celebrity.name, 'Kourtney Kardashian');
        expect(celebrity.confidence, isNull);
      });

      test('parses confidence as int', () {
        final json = {
          'name': 'Test Celebrity',
          'confidence': 1, // int instead of double
        };

        final celebrity = CelebrityModel.fromJson(json);

        expect(celebrity.confidence, 1.0);
      });

      test('parses source fallback key', () {
        final json = {
          'name': 'Test Celebrity',
          'source': 'transcript_mention',
        };

        final celebrity = CelebrityModel.fromJson(json);

        expect(celebrity.recognitionSource, 'transcript_mention');
      });

      test('returns Unknown for null json', () {
        final celebrity = CelebrityModel.fromJson(null);

        expect(celebrity.name, 'Unknown');
        expect(celebrity.confidence, isNull);
        expect(celebrity.recognitionSource, isNull);
      });

      test('returns Unknown for empty json', () {
        final celebrity = CelebrityModel.fromJson({});

        expect(celebrity.name, 'Unknown');
      });
    });

    group('toJson', () {
      test('serializes complete celebrity', () {
        const celebrity = CelebrityModel(
          name: 'Kim Kardashian',
          confidence: 0.95,
          recognitionSource: 'gemini_grounding',
        );

        final json = celebrity.toJson();

        expect(json['name'], 'Kim Kardashian');
        expect(json['confidence'], 0.95);
        expect(json['recognition_source'], 'gemini_grounding');
      });

      test('omits null fields', () {
        const celebrity = CelebrityModel(name: 'Test Celebrity');

        final json = celebrity.toJson();

        expect(json.containsKey('confidence'), isFalse);
        expect(json.containsKey('recognition_source'), isFalse);
      });
    });
  });

  group('parseCelebrities', () {
    test('parses list of celebrities', () {
      final json = [
        {'name': 'Kim Kardashian', 'confidence': 0.95},
        {'name': 'Khloe Kardashian', 'confidence': 0.88},
      ];

      final celebrities = parseCelebrities(json);

      expect(celebrities.length, 2);
      expect(celebrities[0].name, 'Kim Kardashian');
      expect(celebrities[1].name, 'Khloe Kardashian');
    });

    test('returns empty list for null', () {
      final celebrities = parseCelebrities(null);

      expect(celebrities, isEmpty);
    });

    test('returns empty list for non-list', () {
      final celebrities = parseCelebrities('not a list');

      expect(celebrities, isEmpty);
    });

    test('filters out Unknown entries', () {
      final json = [
        {'name': 'Kim Kardashian'},
        {}, // Will become Unknown
        {'name': ''}, // Empty name
      ];

      final celebrities = parseCelebrities(json);

      expect(celebrities.length, 1);
      expect(celebrities[0].name, 'Kim Kardashian');
    });

    test('handles mixed valid and invalid entries', () {
      final json = [
        {'name': 'Valid Celebrity', 'confidence': 0.9},
        null, // Invalid
        'string', // Invalid
        {'full_name': 'Another Celebrity'},
      ];

      final celebrities = parseCelebrities(json);

      expect(celebrities.length, 2);
    });
  });

  group('Equatable', () {
    test('equal celebrities have same props', () {
      const celebrity1 = CelebrityModel(
        name: 'Kim Kardashian',
        confidence: 0.95,
        recognitionSource: 'gemini',
      );
      const celebrity2 = CelebrityModel(
        name: 'Kim Kardashian',
        confidence: 0.95,
        recognitionSource: 'gemini',
      );

      expect(celebrity1, equals(celebrity2));
      expect(celebrity1.props, equals(celebrity2.props));
    });

    test('different celebrities are not equal', () {
      const celebrity1 = CelebrityModel(name: 'Kim Kardashian');
      const celebrity2 = CelebrityModel(name: 'Khloe Kardashian');

      expect(celebrity1, isNot(equals(celebrity2)));
    });
  });
}
