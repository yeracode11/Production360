import '../entities/complete_inventory_request.dart';
import '../entities/create_inventory_request.dart';
import '../entities/create_inventory_result.dart';
import '../entities/inventory_document.dart';

/// Документы инвентаризации (1С /mobile/invent).
abstract class InventoryRepository {
  Future<List<InventoryDocument>> getInventories({
    required String warehouseId,
    DateTime? date,
  });

  Future<InventoryDocument?> getInventoryById(String inventoryId);

  Future<CreateInventoryResult> createInventory(CreateInventoryRequest request);

  Future<CreateInventoryResult> completeInventory(
    CompleteInventoryRequest request,
  );
}
