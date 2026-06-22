import 'package:equatable/equatable.dart';

/// Product line from GET /mobile/zayavka/type/data «products».
class OrderTypeProduct extends Equatable {
  const OrderTypeProduct({
    required this.id,
    required this.name,
    required this.code,
    required this.unit,
    required this.stockBalance,
  });

  final String id;
  final String name;
  final String code;
  final String unit;
  final String stockBalance;

  @override
  List<Object?> get props => [id, name, code, unit, stockBalance];
}
