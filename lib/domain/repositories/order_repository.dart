import '../enums/order_status.dart';
import '../entities/create_order_request.dart';
import '../entities/receipt_order_request.dart';
import '../entities/order_request.dart';
import '../entities/order_type.dart';
import '../entities/order_type_data.dart';

/// Contract for order data.
abstract class OrderRepository {
  /// GET /mobile/zayavka/types?sklad= → «ТипыЗаявок».
  Future<List<OrderType>> fetchOrderTypes({required String warehouseId});

  /// GET /mobile/zayavka/type/data?id=&idSklad= → form data for create order.
  Future<OrderTypeData> fetchOrderTypeData({
    required String orderTypeId,
    required String warehouseId,
  });
  /// GET /mobile/zayavka?sklad=&date= → «Документы».
  ///
  /// [weekDate] — понедельник выбранной недели в формате 1С (YYYYMMDD).
  Future<List<OrderRequest>> getOrders({
    required String outletId,
    OrderStatus? status,
    DateTime? weekDate,
  });

  /// GET /mobile/zayavka?id= → detail in «data».
  Future<OrderRequest?> getOrderById(String orderId);

  /// POST /mobile/zayavka → create order in 1C.
  Future<void> createOrder(CreateOrderRequest request);

  /// PATCH /mobile/zayavka → submit receipt (приёмка).
  Future<void> submitReceipt(ReceiptOrderRequest request);

  Future<void> updateComment({
    required String orderId,
    required String comment,
  });
}
