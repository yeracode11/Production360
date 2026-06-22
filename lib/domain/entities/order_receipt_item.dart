import 'package:equatable/equatable.dart';

/// Receipt line from 1C «ТоварыПриемки» with shipment tracking.
class OrderReceiptItem extends Equatable {
  const OrderReceiptItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.ordered,
    required this.shipped,
    required this.received,
    this.code,
  });

  final String id;
  final String name;
  final String? code;
  final String unit;
  final int ordered;
  final int shipped;
  final int received;

  @override
  List<Object?> get props => [id, name, code, unit, ordered, shipped, received];
}
