import 'package:equatable/equatable.dart';

import 'delivery_date_option.dart';
import 'order_type_product.dart';

/// Form context for a specific order type and warehouse from 1C.
class OrderTypeData extends Equatable {
  const OrderTypeData({
    required this.id,
    required this.name,
    required this.organizationId,
    required this.organizationName,
    required this.warehouseId,
    required this.warehouseName,
    required this.products,
    required this.dates,
    this.forInfo = false,
  });

  final String id;
  final String name;
  final String organizationId;
  final String organizationName;
  final String warehouseId;
  final String warehouseName;
  final List<OrderTypeProduct> products;
  final List<DeliveryDateOption> dates;
  final bool forInfo;

  @override
  List<Object?> get props => [
        id,
        name,
        organizationId,
        organizationName,
        warehouseId,
        warehouseName,
        products,
        dates,
        forInfo,
      ];
}
