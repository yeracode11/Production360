import '../../domain/entities/delivery_date_option.dart';
import '../../domain/entities/order_type_data.dart';
import '../../domain/entities/order_type_product.dart';

class OrderTypeDataModel extends OrderTypeData {
  const OrderTypeDataModel({
    required super.id,
    required super.name,
    required super.organizationId,
    required super.organizationName,
    required super.warehouseId,
    required super.warehouseName,
    required super.products,
    required super.dates,
  });

  factory OrderTypeDataModel.fromJson(Map<String, dynamic> json) {
    final productsJson = json['products'] as List<dynamic>? ?? [];
    final datesJson = json['dates'] as List<dynamic>? ?? [];

    return OrderTypeDataModel(
      id: json['id'] as String,
      name: json['name'] as String,
      organizationId: json['organizationID'] as String,
      organizationName: json['organizarionName'] as String,
      warehouseId: json['skladID'] as String,
      warehouseName: json['skladName'] as String,
      products: productsJson
          .map((e) => OrderTypeProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dates: datesJson
          .map((e) => DeliveryDateOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderTypeProductModel extends OrderTypeProduct {
  const OrderTypeProductModel({
    required super.id,
    required super.name,
    required super.code,
    required super.unit,
    required super.stockBalance,
  });

  factory OrderTypeProductModel.fromJson(Map<String, dynamic> json) {
    return OrderTypeProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      unit: json['edIzm'] as String? ?? '',
      stockBalance: json['ostatok'] as String? ?? '',
    );
  }
}

class DeliveryDateOptionModel extends DeliveryDateOption {
  const DeliveryDateOptionModel({
    required super.value,
    required super.display,
  });

  factory DeliveryDateOptionModel.fromJson(Map<String, dynamic> json) {
    return DeliveryDateOptionModel(
      value: json['date'] as String,
      display: json['dateDisplay'] as String,
    );
  }
}
