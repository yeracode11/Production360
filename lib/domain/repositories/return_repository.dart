import '../entities/create_return_request.dart';
import '../entities/create_return_result.dart';
import '../entities/incoming_invoice.dart';
import '../entities/return_document.dart';
import '../entities/return_predata.dart';

abstract class ReturnRepository {
  Future<List<ReturnDocument>> getReturns({
    required String warehouseId,
    DateTime? date,
  });

  Future<ReturnDocument?> getReturnById(String returnId);

  ReturnPredata? peekCachedPredata(String warehouseId);

  IncomingInvoice? peekCachedIncomingInvoice(String docId);

  Future<ReturnPredata> fetchPredata({
    required String warehouseId,
    bool forceRefresh = false,
  });

  Future<IncomingInvoice?> getIncomingInvoiceById(
    String docId, {
    bool forceRefresh = false,
    String? warehouseId,
    String? warehouseName,
  });

  Future<CreateReturnResult> createReturn(CreateReturnRequest request);
}
