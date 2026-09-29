import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_writeoff_request.dart';
import '../../domain/entities/create_writeoff_result.dart';
import '../../domain/entities/stock_writeoff.dart';
import '../../domain/entities/writeoff_predata.dart';
import '../../domain/repositories/writeoff_repository.dart';
import '../models/create_writeoff_request_model.dart';
import '../models/create_writeoff_result_model.dart';
import '../models/stock_writeoff_model.dart';
import '../models/writeoff_predata_model.dart';

class WriteoffRepositoryImpl implements WriteoffRepository {
  WriteoffRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<List<StockWriteoff>> getWriteoffs({
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
        OneCConfig.stockWriteoffPath,
        queryParameters: queryParameters,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки списаний');

      final docs = json['data'] as List<dynamic>? ?? [];
      final writeoffs = docs
          .map(
            (e) => StockWriteoffModel.from1CListJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
      for (final writeoff in writeoffs) {
        await DocumentAuthorSupport.cacheDocumentAuthor(
          documentId: writeoff.id,
          authorLogin: writeoff.authorLogin,
          author: writeoff.author,
        );
      }
      return writeoffs;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<StockWriteoff?> getWriteoffById(String writeoffId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.stockWriteoffPath,
        queryParameters: {'docID': writeoffId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки списания');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      final writeoff = StockWriteoffModel.from1CDetailJson(data);
      await DocumentAuthorSupport.cacheDocumentAuthor(
        documentId: writeoff.id,
        authorLogin: writeoff.authorLogin,
        author: writeoff.author,
      );
      return writeoff;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<WriteoffPredata> fetchPredata({required String warehouseId}) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.stockWriteoffPredataPath,
        queryParameters: {'skladID': warehouseId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки данных для списания');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      return WriteoffPredataModel.from1CJson(data);
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<CreateWriteoffResult> createWriteoff(
    CreateWriteoffRequest request,
  ) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.stockWriteoffCreatePath,
        data: request.to1CJson(),
        options: _dioClient.documentCreateOptions,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка создания списания');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      final result = CreateWriteoffResultModel.from1CJson(data);
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
