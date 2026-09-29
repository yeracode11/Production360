import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/storage/inventory_completed_storage.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/complete_inventory_request.dart';
import '../../domain/entities/create_inventory_request.dart';
import '../../domain/entities/create_inventory_result.dart';
import '../../domain/entities/inventory_document.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../models/complete_inventory_request_model.dart';
import '../models/create_inventory_request_model.dart';
import '../models/create_inventory_result_model.dart';
import '../models/inventory_document_model.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  InventoryRepositoryImpl({
    required DioClient dioClient,
    required InventoryCompletedStorage completedStorage,
  })  : _dioClient = dioClient,
        _completedStorage = completedStorage;

  final DioClient _dioClient;
  final InventoryCompletedStorage _completedStorage;

  @override
  Future<List<InventoryDocument>> getInventories({
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
        OneCConfig.inventoryPath,
        queryParameters: queryParameters,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки инвентаризаций');

      final docs = json['data'] as List<dynamic>? ?? [];
      final inventories = docs
          .map(
            (e) => InventoryDocumentModel.from1CListJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
      for (final document in inventories) {
        await DocumentAuthorSupport.cacheDocumentAuthor(
          documentId: document.id,
          authorLogin: document.authorLogin,
          author: document.author,
        );
      }
      return inventories;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<InventoryDocument?> getInventoryById(String inventoryId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.inventoryPath,
        queryParameters: {'docID': inventoryId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки инвентаризации');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      final document = InventoryDocumentModel.from1CDetailJson(data);
      if (document.isPosted) {
        await _completedStorage.markCompleted(document.id);
      }
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
  Future<CreateInventoryResult> createInventory(
    CreateInventoryRequest request,
  ) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.inventoryCreatePath,
        data: request.to1CJson(),
        options: _dioClient.documentCreateOptions,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка создания инвентаризации');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      final result = CreateInventoryResultModel.from1CJson(data);
      await DocumentAuthorSupport.rememberCreatedDocument(
        documentId: result.id,
        responseJson: data,
      );
      return result;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<CreateInventoryResult> completeInventory(
    CompleteInventoryRequest request,
  ) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.inventoryCreatePath,
        data: request.to1CJson(),
        options: _dioClient.documentCreateOptions,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка завершения инвентаризации');

      final data = json['data'] as Map<String, dynamic>?;
      await _completedStorage.markCompleted(request.documentId);

      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      return CreateInventoryResultModel.from1CJson(data);
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
