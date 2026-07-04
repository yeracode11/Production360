import 'package:dio/dio.dart';

import '../../core/config/one_c_config.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/one_c_json.dart';
import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_order_request.dart';
import '../../domain/entities/order_type.dart';
import '../../domain/entities/order_type_data.dart';
import '../../domain/enums/order_status.dart';
import '../../domain/entities/order_request.dart';
import '../../domain/entities/receipt_order_request.dart';
import '../../domain/repositories/order_repository.dart';
import '../models/create_order_request_model.dart';
import '../models/receipt_order_request_model.dart';
import '../models/order_request_model.dart';
import '../models/order_type_data_model.dart';
import '../models/order_type_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required DioClient dioClient}) : _dioClient = dioClient;

  final DioClient _dioClient;

  @override
  Future<List<OrderType>> fetchOrderTypes({required String warehouseId}) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.orderTypesPath,
        queryParameters: {'sklad': warehouseId},
      );
      final json = parseOneCJson(response.data);
      final types = json['ТипыЗаявок'] as List<dynamic>? ?? [];
      return types
          .map((e) => OrderTypeModel.from1CJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<OrderTypeData> fetchOrderTypeData({
    required String orderTypeId,
    required String warehouseId,
  }) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.orderTypeDataPath,
        queryParameters: {
          'id': orderTypeId,
          'idSklad': warehouseId,
        },
      );
      final json = parseOneCJson(response.data);
      return OrderTypeDataModel.fromJson(json);
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<List<OrderRequest>> getOrders({
    required String outletId,
    OrderStatus? status,
    DateTime? weekDate,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'sklad': outletId};
      if (weekDate != null) {
        queryParameters['date'] = formatOneCDate(weekDate);
      }

      final response = await _dioClient.instance.get(
        OneCConfig.ordersPath,
        queryParameters: queryParameters,
      );
      final json = parseOneCJson(response.data);
      final docs = json['Документы'] as List<dynamic>? ?? [];
      final orders = docs
          .map(
            (e) => OrderRequestModel.from1CListJson(
              e as Map<String, dynamic>,
              outletId: outletId,
            ),
          )
          .toList();

      if (status != null) {
        return orders.where((o) => o.status == status).toList();
      }
      return orders;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<OrderRequest?> getOrderById(String orderId) async {
    try {
      final response = await _dioClient.instance.get(
        OneCConfig.ordersPath,
        queryParameters: {'id': orderId},
      );
      final json = parseOneCJson(response.data);
      if (json['error'] == true) {
        throw Exception(
          json['error_text'] as String? ?? 'Ошибка загрузки заявки',
        );
      }
      final data = json['data'] as Map<String, dynamic>?;
      if (data == null) {
        return null;
      }
      return OrderRequestModel.from1CDetailJson(data);
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<void> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dioClient.instance.post(
        OneCConfig.ordersPath,
        data: request.to1CJson(),
      );
      _throwIfOneCError(parseOneCJson(response.data), 'Ошибка создания заявки');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<void> submitReceipt(ReceiptOrderRequest request) async {
    try {
      final response = await _dioClient.instance.patch(
        OneCConfig.ordersPath,
        data: request.to1CJson(),
      );
      _throwIfOneCError(parseOneCJson(response.data), 'Ошибка сохранения приёмки');
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  @override
  Future<void> updateComment({
    required String orderId,
    required String comment,
  }) async {
    throw Exception('Комментарий недоступен для редактирования');
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
    if (status == 405) {
      return 'Сервер 1С не поддерживает этот метод запроса. Обратитесь к администратору';
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
          return json['error_text'] as String? ?? fallbackMessage(status);
        }
      } catch (_) {}
    }
    return e.message ?? 'Ошибка запроса к 1С';
  }

  String fallbackMessage(int? status) {
    if (status == 400) return 'Некорректные данные заявки';
    if (status == 404) return 'Заявка не найдена';
    return 'Ошибка запроса к 1С';
  }
}
