import 'package:equatable/equatable.dart';

import '../../../domain/entities/warehouse.dart';

sealed class WarehouseState extends Equatable {
  const WarehouseState();

  @override
  List<Object?> get props => [];
}

final class WarehouseInitial extends WarehouseState {
  const WarehouseInitial();
}

final class WarehouseLoading extends WarehouseState {
  const WarehouseLoading();
}

final class WarehouseLoaded extends WarehouseState {
  const WarehouseLoaded({
    required this.warehouses,
    required this.selectedWarehouse,
  });

  final List<Warehouse> warehouses;
  final Warehouse selectedWarehouse;

  @override
  List<Object?> get props => [warehouses, selectedWarehouse];
}

final class WarehouseEmpty extends WarehouseState {
  const WarehouseEmpty();
}

final class WarehouseFailure extends WarehouseState {
  const WarehouseFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
