import 'package:flutter_test/flutter_test.dart';
import 'package:streamwatch_frontend/data/models/video_type_model.dart';

void main() {
  group('VideoTypeExemplarModel.fromJson', () {
    test('parses weight, image_s3_key, image_url correctly', () {
      final json = {
        'id': 'ex-1',
        'video_type_id': 'type-1',
        'job_id': 'JOB001',
        'exemplar_kind': 'canonical',
        'weight': 3.5,
        'image_s3_key': 'exemplars/ex-1.jpg',
        'image_url': 'https://s3.amazonaws.com/exemplars/ex-1.jpg?signed=abc',
        'notes': 'Test note',
        'added_by': 'user-1',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final model = VideoTypeExemplarModel.fromJson(json);

      expect(model.weight, 3.5);
      expect(model.imageS3Key, 'exemplars/ex-1.jpg');
      expect(model.imageUrl,
          'https://s3.amazonaws.com/exemplars/ex-1.jpg?signed=abc');
    });

    test('missing weight in JSON defaults to 1.0', () {
      final json = {
        'id': 'ex-1',
        'video_type_id': 'type-1',
        'job_id': 'JOB001',
        'exemplar_kind': 'canonical',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final model = VideoTypeExemplarModel.fromJson(json);

      expect(model.weight, 1.0);
    });

    test('weight as integer in JSON parses as double', () {
      final json = {
        'id': 'ex-1',
        'video_type_id': 'type-1',
        'job_id': 'JOB001',
        'exemplar_kind': 'canonical',
        'weight': 1,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final model = VideoTypeExemplarModel.fromJson(json);

      expect(model.weight, 1.0);
      expect(model.weight, isA<double>());
    });

    test('image_url and image_s3_key absent are null', () {
      final json = {
        'id': 'ex-1',
        'video_type_id': 'type-1',
        'job_id': 'JOB001',
        'exemplar_kind': 'canonical',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };

      final model = VideoTypeExemplarModel.fromJson(json);

      expect(model.imageUrl, isNull);
      expect(model.imageS3Key, isNull);
    });
  });
}
