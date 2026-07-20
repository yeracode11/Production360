import '../entities/create_production_request.dart';
import '../entities/create_production_result.dart';
import '../entities/production_document.dart';

/// Документы производства (1С /mobile/proizvodstvo).
abstract class ProductionRepository {
  Future<List<ProductionDocument>> getProductions({
    required String warehouseId,
    DateTime? date,
  });

  Future<ProductionDocument?> getProductionById(String productionId);

  Future<CreateProductionResult> createProduction(
    CreateProductionRequest request,
  );
}
