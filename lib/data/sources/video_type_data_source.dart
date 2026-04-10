import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../models/video_type_model.dart';
import '../providers/rest_client.dart';
import 'auth_data_source.dart';
import '../../shared/errors/exception_handler.dart';
import '../../shared/errors/failures/failure.dart';

/// Interface for TypeControl data operations.
abstract class IVideoTypeDataSource {
  /// Lists all video types.
  Future<Either<Failure, List<VideoTypeModel>>> getVideoTypes();

  /// Gets a single video type by ID.
  Future<Either<Failure, VideoTypeModel>> getVideoType(String id);

  /// Lists versions for a video type.
  Future<Either<Failure, List<VideoTypeVersionModel>>> getVersions(
      String videoTypeId);

  /// Lists rules for a version.
  Future<Either<Failure, List<VideoTypeRuleModel>>> getRules(String versionId);

  /// Renders the prompt for a video type's active version.
  Future<Either<Failure, RenderedPromptModel>> renderTypePrompt(
      String videoTypeId);

  /// Renders the prompt for a specific version.
  Future<Either<Failure, RenderedPromptModel>> renderVersionPrompt(
      String versionId);

  /// Activates a version (POST /versions/{id}/activate).
  Future<Either<Failure, VideoTypeVersionModel>> activateVersion(
      String versionId);

  /// Rolls back a video type to the previous version.
  Future<Either<Failure, VideoTypeVersionModel>> rollbackVersion(
      String videoTypeId);

  // --- Rules CRUD ---

  Future<Either<Failure, VideoTypeRuleModel>> createRule(
      String versionId, Map<String, dynamic> body);

  Future<Either<Failure, VideoTypeRuleModel>> updateRule(
      String ruleId, Map<String, dynamic> body);

  Future<Either<Failure, VideoTypeRuleModel>> deprecateRule(String ruleId);

  Future<Either<Failure, List<VideoTypeRuleModel>>> reorderRules(
      String versionId, List<String> orderedRuleIds);

  // --- Candidates ---

  Future<Either<Failure, List<VideoTypeRuleCandidateModel>>> getCandidates(
      String videoTypeId);

  Future<Either<Failure, VideoTypeRuleCandidateModel>> approveCandidate(
      String candidateId, Map<String, dynamic> body);

  Future<Either<Failure, VideoTypeRuleCandidateModel>> rejectCandidate(
      String candidateId, String reason);

  Future<Either<Failure, VideoTypeRuleCandidateModel>> mergeCandidate(
      String candidateId, Map<String, dynamic> body);

  // --- Exemplars ---

  Future<Either<Failure, List<VideoTypeExemplarModel>>> getExemplars(
      String videoTypeId);

  Future<Either<Failure, List<VideoTypeExemplarModel>>> bulkCreateExemplars(
      String videoTypeId, Map<String, dynamic> body);

  Future<Either<Failure, void>> deleteExemplar(String exemplarId);

  /// Updates an exemplar via PATCH /exemplars/{exemplar_id}.
  /// Only non-null fields are included in the request body.
  Future<Either<Failure, void>> updateExemplar(
    String exemplarId, {
    double? weight,
    String? notes,
    String? exemplarKind,
  });

  /// Uploads an image for an exemplar via POST /exemplars/{exemplar_id}/image.
  /// Returns the image URL on success.
  Future<Either<Failure, String>> uploadExemplarImage(
    String exemplarId,
    String filePath,
  );
}

/// HTTP implementation of IVideoTypeDataSource.
class VideoTypeDataSource implements IVideoTypeDataSource {
  final IAuthDataSource _auth;
  final IRestClient _client;

  const VideoTypeDataSource({
    required IAuthDataSource auth,
    required IRestClient client,
  })  : _auth = auth,
        _client = client;

  @override
  Future<Either<Failure, List<VideoTypeModel>>> getVideoTypes() =>
      ExceptionHandler<List<VideoTypeModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') {
              return const Right([]);
            }

            final decoded = json.decode(body);
            if (decoded is! List) {
              return const Right([]);
            }

            final types = decoded
                .map((e) => VideoTypeModel.fromJson(e as Map<String, dynamic>))
                .toList();
            return Right(types);
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeModel>> getVideoType(String id) =>
      ExceptionHandler<VideoTypeModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types/$id',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                VideoTypeModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, List<VideoTypeVersionModel>>> getVersions(
          String videoTypeId) =>
      ExceptionHandler<List<VideoTypeVersionModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/versions',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') {
              return const Right([]);
            }

            final decoded = json.decode(body);
            if (decoded is! List) {
              return const Right([]);
            }

            final versions = decoded
                .map((e) =>
                    VideoTypeVersionModel.fromJson(e as Map<String, dynamic>))
                .toList();
            return Right(versions);
          },
        );
      }).call();

  @override
  Future<Either<Failure, List<VideoTypeRuleModel>>> getRules(
          String versionId) =>
      ExceptionHandler<List<VideoTypeRuleModel>>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/versions/$versionId/rules',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final body = response.body;
            if (body.isEmpty || body == 'null') {
              return const Right([]);
            }

            final decoded = json.decode(body);
            if (decoded is! List) {
              return const Right([]);
            }

            final rules = decoded
                .map((e) =>
                    VideoTypeRuleModel.fromJson(e as Map<String, dynamic>))
                .toList();
            return Right(rules);
          },
        );
      }).call();

  @override
  Future<Either<Failure, RenderedPromptModel>> renderTypePrompt(
          String videoTypeId) =>
      ExceptionHandler<RenderedPromptModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/prompt',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                RenderedPromptModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, RenderedPromptModel>> renderVersionPrompt(
          String versionId) =>
      ExceptionHandler<RenderedPromptModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/versions/$versionId/prompt',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(
                RenderedPromptModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeVersionModel>> activateVersion(
          String versionId) =>
      ExceptionHandler<VideoTypeVersionModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/versions/$versionId/activate',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(VideoTypeVersionModel.fromJson(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeVersionModel>> rollbackVersion(
          String videoTypeId) =>
      ExceptionHandler<VideoTypeVersionModel>(() async {
        final tokenResult = await _auth.getAuthToken();

        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/rollback',
              authToken: authToken,
            );

            if (response.statusCode != HttpStatus.created) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            return Right(VideoTypeVersionModel.fromJson(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  // --- Rules CRUD ---

  @override
  Future<Either<Failure, VideoTypeRuleModel>> createRule(
          String versionId, Map<String, dynamic> body) =>
      ExceptionHandler<VideoTypeRuleModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/versions/$versionId/rules',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.created &&
                response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(
                VideoTypeRuleModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeRuleModel>> updateRule(
          String ruleId, Map<String, dynamic> body) =>
      ExceptionHandler<VideoTypeRuleModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.patch(
              endPoint: '/api/v1/typecontrol/rules/$ruleId',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(
                VideoTypeRuleModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeRuleModel>> deprecateRule(String ruleId) =>
      ExceptionHandler<VideoTypeRuleModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/rules/$ruleId/deprecate',
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(
                VideoTypeRuleModel.fromJson(decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, List<VideoTypeRuleModel>>> reorderRules(
          String versionId, List<String> orderedRuleIds) =>
      ExceptionHandler<List<VideoTypeRuleModel>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/versions/$versionId/rules/reorder',
              authToken: authToken,
              body: {'ordered_rule_ids': orderedRuleIds},
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            if (decoded is! List) return const Right([]);
            return Right(decoded
                .map((e) =>
                    VideoTypeRuleModel.fromJson(e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  // --- Candidates ---

  @override
  Future<Either<Failure, List<VideoTypeRuleCandidateModel>>> getCandidates(
          String videoTypeId) =>
      ExceptionHandler<List<VideoTypeRuleCandidateModel>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/candidates',
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final body = response.body;
            if (body.isEmpty || body == 'null') return const Right([]);
            final decoded = json.decode(body);
            if (decoded is! List) return const Right([]);
            return Right(decoded
                .map((e) => VideoTypeRuleCandidateModel.fromJson(
                    e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeRuleCandidateModel>> approveCandidate(
          String candidateId, Map<String, dynamic> body) =>
      ExceptionHandler<VideoTypeRuleCandidateModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/candidates/$candidateId/approve',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(VideoTypeRuleCandidateModel.fromJson(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeRuleCandidateModel>> rejectCandidate(
          String candidateId, String reason) =>
      ExceptionHandler<VideoTypeRuleCandidateModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/candidates/$candidateId/reject',
              authToken: authToken,
              body: {'reason': reason},
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(VideoTypeRuleCandidateModel.fromJson(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  @override
  Future<Either<Failure, VideoTypeRuleCandidateModel>> mergeCandidate(
          String candidateId, Map<String, dynamic> body) =>
      ExceptionHandler<VideoTypeRuleCandidateModel>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/candidates/$candidateId/merge',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            return Right(VideoTypeRuleCandidateModel.fromJson(
                decoded as Map<String, dynamic>));
          },
        );
      }).call();

  // --- Exemplars ---

  @override
  Future<Either<Failure, List<VideoTypeExemplarModel>>> getExemplars(
          String videoTypeId) =>
      ExceptionHandler<List<VideoTypeExemplarModel>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.get(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/exemplars',
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final body = response.body;
            if (body.isEmpty || body == 'null') return const Right([]);
            final decoded = json.decode(body);
            if (decoded is! List) return const Right([]);
            return Right(decoded
                .map((e) =>
                    VideoTypeExemplarModel.fromJson(e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  @override
  Future<Either<Failure, List<VideoTypeExemplarModel>>> bulkCreateExemplars(
          String videoTypeId, Map<String, dynamic> body) =>
      ExceptionHandler<List<VideoTypeExemplarModel>>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.post(
              endPoint: '/api/v1/typecontrol/types/$videoTypeId/exemplars/bulk',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.created &&
                response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            final decoded = json.decode(response.body);
            if (decoded is! List) return const Right([]);
            return Right(decoded
                .map((e) =>
                    VideoTypeExemplarModel.fromJson(e as Map<String, dynamic>))
                .toList());
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> deleteExemplar(String exemplarId) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final response = await _client.delete(
              endPoint: '/api/v1/typecontrol/exemplars/$exemplarId',
              authToken: authToken,
            );
            if (response.statusCode != HttpStatus.ok &&
                response.statusCode != HttpStatus.noContent) {
              return Left(HttpFailure.fromResponse(response));
            }
            return const Right(null);
          },
        );
      }).call();

  @override
  Future<Either<Failure, void>> updateExemplar(
    String exemplarId, {
    double? weight,
    String? notes,
    String? exemplarKind,
  }) =>
      ExceptionHandler<void>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final body = <String, dynamic>{};
            if (weight != null) body['weight'] = weight;
            if (notes != null) body['notes'] = notes;
            if (exemplarKind != null) body['exemplar_kind'] = exemplarKind;

            final response = await _client.patch(
              endPoint: '/api/v1/typecontrol/exemplars/$exemplarId',
              authToken: authToken,
              body: body,
            );
            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }
            return const Right(null);
          },
        );
      }).call();

  @override
  Future<Either<Failure, String>> uploadExemplarImage(
    String exemplarId,
    String filePath,
  ) =>
      ExceptionHandler<String>(() async {
        final tokenResult = await _auth.getAuthToken();
        return tokenResult.fold(
          (failure) => Left(failure),
          (authToken) async {
            final uri = Uri.parse(
                '${_client.baseUrl}/api/v1/typecontrol/exemplars/$exemplarId/image');
            final request = http.MultipartRequest('POST', uri);
            request.headers['Authorization'] = 'Bearer $authToken';
            request.files.add(
              await http.MultipartFile.fromPath('image', filePath),
            );

            final streamed = await _client.sendMultipart(request: request);
            final response = await http.Response.fromStream(streamed);

            if (response.statusCode != HttpStatus.ok) {
              return Left(HttpFailure.fromResponse(response));
            }

            final decoded = json.decode(response.body);
            final imageUrl = decoded['image_url'] as String? ?? '';
            return Right(imageUrl);
          },
        );
      }).call();
}
