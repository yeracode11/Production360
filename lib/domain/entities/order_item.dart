import 'package:equatable/equatable.dart';

import '../../core/utils/amount_parser.dart';

/// Line item within an order request.
class OrderItem extends Equatable {
  const OrderItem({
    required this.name,
    required this.quantity,
    this.unit,
    this.id,
  });

  final String? id;
  final String name;
  final double quantity;
  final String? unit;

  /// Formatted quantity for display, e.g. "10 кг" or "0,5 шт."
  String get quantityLabel {
    final qty = formatQuantityForInput(quantity);
    if (unit != null && unit!.isNotEmpty) {
      return '$qty $unit';
    }
    return qty;
  }

  @override
  List<Object?> get props => [id, name, quantity, unit];
}
