import 'package:equatable/equatable.dart';

/// Принтер склада из GET /mobile/printers.
class WarehousePrinter extends Equatable {
  const WarehousePrinter({
    required this.address,
    required this.name,
  });

  final String address;
  final String name;

  @override
  List<Object?> get props => [address, name];
}
