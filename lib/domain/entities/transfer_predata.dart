import 'package:equatable/equatable.dart';

/// Данные для формы создания перемещения (GET /internaltransfer/predata).
class TransferPredata extends Equatable {
  const TransferPredata({
    required this.organizationId,
    required this.organizationName,
    required this.availableWarehouses,
  });

  final String organizationId;
  final String organizationName;
  final List<TransferWarehouseOption> availableWarehouses;

  @override
  List<Object?> get props => [
        organizationId,
        organizationName,
        availableWarehouses,
      ];
}

class TransferWarehouseOption extends Equatable {
  const TransferWarehouseOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
