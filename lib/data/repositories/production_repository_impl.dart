import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_production_request.dart';
import '../../domain/entities/create_production_result.dart';
import '../../domain/entities/production_document.dart';
import '../../domain/entities/transfer_predata.dart';
import '../../domain/repositories/production_repository.dart';
import '../models/create_production_request_model.dart';
import '../models/create_production_result_model.dart';
import '../models/production_document_model.dart';
import '../models/transfer_predata_model.dart';

class ProductionRepositoryImpl implements ProductionRepository {
  ProductionRepositoryImpl({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<List<ProductionDocument>> getProductions({
    required String warehouseId,
    DateTime? date,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'skladID': warehouseId,
      };
      if (date != null) {
        queryParameters['date'] = formatOneCDate(date);
      }

      final response = await _dioClient.instance.get(
        OneCConfig.productionPath,
        queryParameters: queryParameters,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки производств');

      final docs = json['data'] as List<dynamic>? ?? [];
      final productions = docs
          .map(
            (e) => ProductionDocumentModel.from1CListJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
      for (final document in productions) {
        await DocumentAuthorSupport.cacheDocumentAuthor(
          documentId: document.id,
          authorLogin: document.authorLogin,
          author: document.author,
        );
      }
      return productions;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<ProductionDocument?> getProductionById(String productionId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.productionPath,
        queryParameters: {'docID': productionId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки производства');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      final document = ProductionDocumentModel.from1CDetailJson(data);
      await DocumentAuthorSupport.cacheDocumentAuthor(
        documentId: document.id,
        authorLogin: document.authorLogin,
        author: document.author,
      );
      return document;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<TransferPredata> fetchPredata({required String warehouseId}) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.productionPredataPath,
        queryParameters: {'skladID': warehouseId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки данных для производства');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      return TransferPredataModel.from1CJson(data);
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<CreateProductionResult> createProduction(
    CreateProductionRequest request,
  ) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.productionCreatePath,
        data: request.to1CJson(),
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка создания производства');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      final result = CreateProductionResultModel.from1CJson(data);
      await DocumentAuthorSupport.rememberCreatedDocument(
        documentId: result.id,
        responseJson: data,
      );
      return result;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  void _throwIfOneCError(Map<String, dynamic> json, String fallback) {
    if (json['error'] == true) {
      throw Exception(json['error_text'] as String? ?? fallback);
    }
  }

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Неверный логин или пароль';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер 1С не отвечает';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Не удалось подключиться к серверу';
    }
    final body = e.response?.data;
    if (body != null) {
      try {
        final json = parseOneCJson(body);
        if (json['error'] == true) {
          return json['error_text'] as String? ?? 'Ошибка запроса к 1С';
        }
      } catch (_) {}
    }
    return e.message ?? 'Ошибка запроса к 1С';
  }
}
