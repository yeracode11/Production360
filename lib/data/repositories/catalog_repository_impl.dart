import 'package:dio/dio.dart';

import '../../core/config/catalog_config.dart';
import '../../domain/entities/nomenclature_page.dart';
import '../../domain/entities/nomenclature_product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../models/nomenclature_product_model.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<NomenclaturePage> searchNomenclature({
    required String organizationId,
    required String query,
    int limit = 30,
    int offset = 0,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return NomenclaturePage(items: const [], total: 0, offset: offset, limit: limit);
    }

    return _fetchPage(
      organizationId: organizationId,
      queryParameters: {
        'organizationID': organizationId,
        'q': trimmed,
        'limit': limit,
        'offset': offset,
      },
      filterProducts: true,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<NomenclaturePage> listNomenclatureGroups({
    required String organizationId,
    String? parentId,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParameters = <String, dynamic>{
      'organizationID': organizationId,
      'groupsOnly': true,
      'limit': limit,
      'offset': offset,
    };
    final trimmedParent = parentId?.trim();
    if (trimmedParent != null && trimmedParent.isNotEmpty) {
      queryParameters['parentID'] = trimmedParent;
    }

    return _fetchPage(
      organizationId: organizationId,
      queryParameters: queryParameters,
      filterProducts: false,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<NomenclaturePage> listNomenclatureProducts({
    required String organizationId,
    required String parentId,
    int limit = 30,
    int offset = 0,
  }) async {
    return _fetchPage(
      organizationId: organizationId,
      queryParameters: {
        'organizationID': organizationId,
        'parentID': parentId.trim(),
        'groupsOnly': false,
        'limit': limit,
        'offset': offset,
      },
      filterProducts: true,
      offset: offset,
      limit: limit,
    );
  }

  Future<NomenclaturePage> _fetchPage({
    required String organizationId,
    required Map<String, dynamic> queryParameters,
    required bool filterProducts,
    required int offset,
    required int limit,
  }) async {
    try {
      final response = await _dio.get(
        CatalogConfig.nomenclatureSearchPath,
        queryParameters: queryParameters,
      );
      final json = response.data as Map<String, dynamic>;
      final items = json['items'] as List<dynamic>? ?? [];
      final total = (json['total'] as num?)?.toInt() ?? items.length;

      final parsed = items
          .map(
            (e) => NomenclatureProductModel.fromCatalogJson(
              e as Map<String, dynamic>,
            ),
          )
          .where(
            (item) =>
                !filterProducts ||
                !item.isGroup && _isVisibleForOrganization(item, organizationId),
          )
          .toList();

      return NomenclaturePage(
        items: parsed,
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

  /// Пустые места использования + галочка → для всех организаций.
  /// Иначе — только если организация есть в [usagePlaces].
  bool _isVisibleForOrganization(
    NomenclatureProduct product,
    String organizationId,
  ) {
    if (!product.showInMobileApp) return false;
    if (product.usagePlaces.isEmpty) return true;

    final orgId = organizationId.trim().toLowerCase();
    if (orgId.isEmpty) return true;

    return product.usagePlaces.any(
      (place) =>
          place.type.toLowerCase() == 'organization' &&
          place.id.trim().toLowerCase() == orgId,
    );
  }
}
