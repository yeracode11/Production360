import '../entities/create_transfer_request.dart';
import '../entities/create_transfer_result.dart';
import '../entities/internal_transfer.dart';
import '../entities/transfer_predata.dart';

/// Документы внутреннего перемещения (1С /mobile/internaltransfer).
abstract class TransferRepository {
  /// GET ?skladID=&date= → список в «data».
  Future<List<InternalTransfer>> getTransfers({
    required String warehouseId,
    DateTime? date,
  });

  /// GET ?docID= → деталь в «data».
  Future<InternalTransfer?> getTransferById(String transferId);

  /// GET /predata?skladID= → организация и склады-отправители.
  Future<TransferPredata> fetchPredata({required String warehouseId});

  /// POST /create → создаёт и проводит документ. При error=true бросает Exception(error_text).
  Future<CreateTransferResult> createTransfer(CreateTransferRequest request);
}
