import 'package:dio/dio.dart';

import '../../core/config/catalog_config.dart';
import '../../domain/entities/nomenclature_page.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/order_type_data_model.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<NomenclaturePage> searchNomenclature({
    String? query,
    int limit = 30,
    int offset = 0,
  }) async {
    final trimmed = query?.trim();
    final queryParameters = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (trimmed != null && trimmed.isNotEmpty) {
      queryParameters['q'] = trimmed;
    }

    try {
      final response = await _dio.get(
        CatalogConfig.nomenclatureSearchPath,
        queryParameters: queryParameters,
      );
      final json = response.data as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>? ?? [];
      final total = (json['total'] as num?)?.toInt() ?? items.length;

      return NomenclaturePage(
        items: items
            .map(
              (e) => OrderTypeProductModel.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        total: total,
        offset: offset,
        limit: limit,
      );
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      return 'Неверный токен каталога';
    }
    if (status == 502 || status == 503 || status == 504) {
      return 'Сервер каталога временно недоступен. Попробуйте позже';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Сервер каталога не отвечает';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Не удалось подключиться к серверу каталога';
    }
    return e.message ?? 'Ошибка поиска номенклатуры';
  }
}
