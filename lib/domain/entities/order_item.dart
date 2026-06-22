import 'package:equatable/equatable.dart';

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
  final int quantity;
  final String? unit;

  /// Formatted quantity for display, e.g. "10 кг" or "50 шт."
  String get quantityLabel {
    if (unit != null && unit!.isNotEmpty) {
      return '$quantity $unit';
    }
    return quantity.toString();
  }

  @override
  List<Object?> get props => [id, name, quantity, unit];
}
