import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_return_request.dart';
import '../../domain/entities/create_return_result.dart';
import '../../domain/entities/incoming_invoice.dart';
import '../../domain/entities/return_document.dart';
import '../../domain/entities/return_predata.dart';
import '../../domain/repositories/return_repository.dart';
import '../models/create_return_request_model.dart';
import '../models/create_return_result_model.dart';
import '../models/incoming_invoice_model.dart';
import '../models/return_document_model.dart';
import '../models/return_predata_model.dart';

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.fetchedAt});

  final T value;
  final DateTime fetchedAt;

  bool isFresh(Duration ttl) => DateTime.now().difference(fetchedAt) <= ttl;
}

class ReturnRepositoryImpl implements ReturnRepository {
  ReturnRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  static const _cacheTtl = Duration(minutes: 10);

  final DioClient _dioClient;
  final Map<String, _CacheEntry<ReturnPredata>> _predataCache = {};
  final Map<String, _CacheEntry<IncomingInvoice>> _invoiceCache = {};
  final Map<String, Future<ReturnPredata>> _predataInFlight = {};
  final Map<String, Future<IncomingInvoice?>> _invoiceInFlight = {};

  @override
  ReturnPredata? peekCachedPredata(String warehouseId) {
    final entry = _predataCache[warehouseId];
    if (entry == null || !entry.isFresh(_cacheTtl)) {
      return null;
    }
    return entry.value;
  }

  @override
  IncomingInvoice? peekCachedIncomingInvoice(String docId) {
    final entry = _invoiceCache[docId];
    if (entry == null || !entry.isFresh(_cacheTtl)) {
      return null;
    }
    return entry.value;
  }

  @override
  Future<List<ReturnDocument>> getReturns({
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
        OneCConfig.returnsPath,
        queryParameters: queryParameters,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки возвратов');

      final data = json['data'];
      if (data is! List) {
        return [];
      }

      final returns = await Future.wait(
        data.map((e) async {
          final doc = ReturnDocumentModel.from1CListJson(
            e as Map<String, dynamic>,
          );
          return _enrichSenderOrganization(doc);
        }),
      );
      await Future.wait(
        returns.map(
          (doc) => DocumentAuthorSupport.cacheDocumentAuthor(
            documentId: doc.id,
            authorLogin: doc.authorLogin,
            author: doc.author,
          ),
        ),
      );
      return returns;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<ReturnDocument?> getReturnById(String returnId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.returnsPath,
        queryParameters: {'docID': returnId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки возврата');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      final doc = await _enrichSenderOrganization(
        ReturnDocumentModel.from1CDetailJson(data),
      );
      await DocumentAuthorSupport.cacheDocumentAuthor(
        documentId: doc.id,
        authorLogin: doc.authorLogin,
        author: doc.author,
      );
      return doc;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<ReturnPredata> fetchPredata({
    required String warehouseId,
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = peekCachedPredata(warehouseId);
      if (cached != null) {
        return Future.value(cached);
      }
      final inFlight = _predataInFlight[warehouseId];
      if (inFlight != null) {
        return inFlight;
      }
    }

    final request = _fetchPredataFromApi(warehouseId);
    _predataInFlight[warehouseId] = request;
    return request.whenComplete(() => _predataInFlight.remove(warehouseId));
  }

  Future<ReturnPredata> _fetchPredataFromApi(String warehouseId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.returnsPredataPath,
        queryParameters: {'skladID': warehouseId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки данных для возврата');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      final predata = ReturnPredataModel.from1CJson(data);
      _predataCache[warehouseId] = _CacheEntry(
        value: predata,
        fetchedAt: DateTime.now(),
      );
      return predata;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<IncomingInvoice?> getIncomingInvoiceById(
    String docId, {
    bool forceRefresh = false,
    String? warehouseId,
    String? warehouseName,
  }) {
    if (!forceRefresh) {
      final cached = peekCachedIncomingInvoice(docId);
      if (cached != null) {
        return _enrichRecipientOrganization(
          cached as IncomingInvoiceModel,
          warehouseId: warehouseId,
          warehouseName: warehouseName,
        );
      }
      final inFlight = _invoiceInFlight[docId];
      if (inFlight != null) {
        return inFlight;
      }
    }

    final request = _fetchIncomingInvoiceFromApi(
      docId,
      warehouseId: warehouseId,
      warehouseName: warehouseName,
    );
    _invoiceInFlight[docId] = request;
    return request.whenComplete(() => _invoiceInFlight.remove(docId));
  }

  Future<IncomingInvoice?> _fetchIncomingInvoiceFromApi(
    String docId, {
    String? warehouseId,
    String? warehouseName,
  }) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.incomingInvoicePath,
        queryParameters: {'docID': docId},
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка загрузки приходной накладной');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      final invoice = await _enrichRecipientOrganization(
        IncomingInvoiceModel.from1CDetailJson(data),
        warehouseId: warehouseId,
        warehouseName: warehouseName,
      );
      _invoiceCache[docId] = _CacheEntry(
        value: invoice,
        fetchedAt: DateTime.now(),
      );
      return invoice;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<CreateReturnResult> createReturn(CreateReturnRequest request) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.returnsCreatePath,
        data: request.to1CJson(),
        options: _dioClient.documentCreateOptions,
      );
      final json = parseOneCJson(response.data);
      _throwIfOneCError(json, 'Ошибка создания возврата');

      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Пустой ответ от 1С');
      }
      final result = CreateReturnResultModel.from1CJson(data);
      _predataCache.remove(request.warehouseId);
      _invoiceCache.remove(request.incomingInvoiceId);
      await DocumentAuthorSupport.rememberCreatedDocument(
        documentId: result.id,
        responseJson: data,
      );
      return result;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  Future<IncomingInvoiceModel> _enrichRecipientOrganization(
    IncomingInvoiceModel invoice, {
    String? warehouseId,
    String? warehouseName,
  }) async {
    var enriched = invoice;

    if (enriched.warehouseName.trim().isEmpty &&
        warehouseName != null &&
        warehouseName.trim().isNotEmpty) {
      enriched = enriched.copyWith(warehouseName: warehouseName.trim());
    }

    if (enriched.organizationName.trim().isEmpty) {
      final cachedName = _resolveRecipientOrganizationName(
        enriched,
        warehouseId: warehouseId,
      );
      if (cachedName != null) {
        enriched = enriched.copyWith(organizationName: cachedName);
      }
    }

    if (enriched.organizationName.trim().isEmpty &&
        warehouseId != null &&
        warehouseId.isNotEmpty) {
      try {
        final predata = await fetchPredata(warehouseId: warehouseId);
        if (predata.organizationName.trim().isNotEmpty &&
            (enriched.organizationId.isEmpty ||
                predata.organizationId == enriched.organizationId)) {
          enriched = enriched.copyWith(
            organizationName: predata.organizationName,
          );
        }
      } catch (_) {}
    }

    return enriched;
  }

  String? _resolveRecipientOrganizationName(
    IncomingInvoice invoice, {
    String? warehouseId,
  }) {
    if (warehouseId != null && warehouseId.isNotEmpty) {
      final warehouseEntry = _predataCache[warehouseId];
      if (warehouseEntry != null && warehouseEntry.isFresh(_cacheTtl)) {
        final predata = warehouseEntry.value;
        if (predata.organizationName.trim().isNotEmpty &&
            (invoice.organizationId.isEmpty ||
                predata.organizationId == invoice.organizationId)) {
          return predata.organizationName;
        }
      }
    }

    for (final entry in _predataCache.values) {
      final predata = entry.value;
      if (predata.organizationName.trim().isEmpty) {
        continue;
      }
      if (invoice.organizationId.isNotEmpty &&
          predata.organizationId == invoice.organizationId) {
        return predata.organizationName;
      }
    }

    return null;
  }

  Future<ReturnDocumentModel> _enrichSenderOrganization(
    ReturnDocumentModel doc,
  ) async {
    if (doc.senderOrganizationName.trim().isNotEmpty) {
      return doc;
    }

    final cachedName = _resolveSenderOrganizationName(doc);
    if (cachedName != null) {
      return doc.copyWith(senderOrganizationName: cachedName);
    }

    if (doc.senderWarehouseId.isEmpty) {
      return doc;
    }

    try {
      final predata = await fetchPredata(warehouseId: doc.senderWarehouseId);
      if (predata.organizationName.trim().isEmpty) {
        return doc;
      }
      if (doc.senderOrganizationId.isNotEmpty &&
          predata.organizationId != doc.senderOrganizationId) {
        return doc;
      }
      return doc.copyWith(senderOrganizationName: predata.organizationName);
    } catch (_) {
      return doc;
    }
  }

  String? _resolveSenderOrganizationName(ReturnDocument doc) {
    final warehouseEntry = _predataCache[doc.senderWarehouseId];
    if (warehouseEntry != null && warehouseEntry.isFresh(_cacheTtl)) {
      final predata = warehouseEntry.value;
      if (predata.organizationName.trim().isNotEmpty &&
          (doc.senderOrganizationId.isEmpty ||
              predata.organizationId == doc.senderOrganizationId)) {
        return predata.organizationName;
      }
    }

    for (final entry in _predataCache.values) {
      final predata = entry.value;
      if (predata.organizationName.trim().isEmpty) {
        continue;
      }
      if (doc.senderOrganizationId.isNotEmpty &&
          predata.organizationId == doc.senderOrganizationId) {
        return predata.organizationName;
      }
    }

    return null;
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
