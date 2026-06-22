import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/storage/selected_warehouse_storage.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'warehouse_state.dart';

/// Warehouses (торговые точки) loaded from 1C GET /mobile/auth → «Склады».
class WarehouseCubit extends Cubit<WarehouseState> {
  WarehouseCubit({
    required AuthRepository authRepository,
    required SelectedWarehouseStorage storage,
  })  : _authRepository = authRepository,
        _storage = storage,
        super(const WarehouseInitial());

  final AuthRepository _authRepository;
  final SelectedWarehouseStorage _storage;

  /// Fetches warehouse list from 1C API.
  Future<void> loadFromApi({Warehouse? keepSelected}) async {
    emit(const WarehouseLoading());
    try {
      final warehouses = await _authRepository.fetchWarehousesFromApi();
      if (warehouses.isEmpty) {
        emit(const WarehouseEmpty());
        return;
      }

      final selected = await _resolveSelection(warehouses, keepSelected);
      emit(WarehouseLoaded(warehouses: warehouses, selectedWarehouse: selected));
    } catch (e) {
      emit(WarehouseFailure(e.toString()));
    }
  }

  /// Silent refresh — keeps current UI, no loading spinner.
  Future<void> refreshFromApi() async {
    Warehouse? keepSelected;
    if (state is WarehouseLoaded) {
      keepSelected = (state as WarehouseLoaded).selectedWarehouse;
    }
    try {
      final warehouses = await _authRepository.fetchWarehousesFromApi();
      if (warehouses.isEmpty) {
        emit(const WarehouseEmpty());
        return;
      }
      final selected = await _resolveSelection(warehouses, keepSelected);
      emit(WarehouseLoaded(warehouses: warehouses, selectedWarehouse: selected));
    } catch (e) {
      emit(WarehouseFailure(e.toString()));
    }
  }

  Future<void> selectWarehouse(Warehouse warehouse) async {
    final current = state;
    if (current is WarehouseLoaded) {
      emit(WarehouseLoaded(
        warehouses: current.warehouses,
        selectedWarehouse: warehouse,
      ));
      await _persistSelection(warehouse);
    }
  }

  /// Сбрасывает состояние cubit. Сохранённая точка в storage не удаляется.
  void reset() {
    emit(const WarehouseInitial());
  }

  Future<Warehouse> _resolveSelection(
    List<Warehouse> warehouses,
    Warehouse? keepSelected,
  ) async {
    if (keepSelected != null) {
      for (final w in warehouses) {
        if (w.id == keepSelected.id) return w;
      }
    }

    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      final persisted = _storage.readForUser(user.uid);
      if (persisted.id != null) {
        for (final w in warehouses) {
          if (w.id == persisted.id) return w;
        }
      }
      if (persisted.name != null) {
        for (final w in warehouses) {
          if (w.name == persisted.name) return w;
        }
      }
    }

    final current = state;
    if (current is WarehouseLoaded) {
      for (final w in warehouses) {
        if (w.id == current.selectedWarehouse.id) return w;
      }
    }

    return warehouses.first;
  }

  Future<void> _persistSelection(Warehouse warehouse) async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return;
    await _storage.save(
      userId: user.uid,
      warehouseId: warehouse.id,
      warehouseName: warehouse.name,
    );
  }
}
