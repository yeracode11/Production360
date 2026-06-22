import 'package:dio/dio.dart';

import '../../core/config/catalog_config.dart';
import '../../core/utils/order_item_display.dart';
import '../../domain/entities/order_type_product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/order_type_data_model.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<OrderTypeProduct>> searchNomenclature(
    String query, {
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        CatalogConfig.nomenclatureSearchPath,
        queryParameters: {
          'q': trimmed,
          'limit': limit,
        },
      );
      final json = response.data as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>? ?? [];

      return items
          .where((raw) {
            final map = raw as Map<String, dynamic>;
            return isSelectableCreateOrderProduct(
              name: map['name'] as String? ?? '',
              productType: map['product_type'] as String?,
            );
          })
          .map(
            (e) => OrderTypeProductModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  String _mapDioError(DioException e) {
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
