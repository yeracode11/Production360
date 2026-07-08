import '../entities/create_writeoff_request.dart';
import '../entities/create_writeoff_result.dart';
import '../entities/stock_writeoff.dart';
import '../entities/writeoff_predata.dart';

/// Документы списания запасов (1С /mobile/spisaniyezapasov).
abstract class WriteoffRepository {
  Future<List<StockWriteoff>> getWriteoffs({
    required String warehouseId,
    DateTime? date,
  });

  Future<StockWriteoff?> getWriteoffById(String writeoffId);

  Future<WriteoffPredata> fetchPredata({required String warehouseId});

  Future<CreateWriteoffResult> createWriteoff(CreateWriteoffRequest request);
}
