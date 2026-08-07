import '../../core/constants/app_strings.dart';
import '../../core/utils/amount_parser.dart';
import '../../core/utils/document_author_support.dart';
import '../../core/utils/order_item_display.dart';
import '../entities/inventory_document.dart';
import '../entities/internal_transfer.dart';
import '../entities/order_item.dart';
import '../entities/order_request.dart';
import '../entities/printable_document.dart';
import '../entities/production_document.dart';
import '../entities/stock_writeoff.dart';

/// Преобразует доменные документы в формат для печати (поля как в «Основное» на экране).
abstract final class DocumentPrintMapper {
  static PrintableDocument fromOrder(OrderRequest order) {
    final visibleItems = order.items
        .map((item) => _mapOrderItem(item))
        .whereType<PrintableItem>()
        .toList();

    final orderTypeLabel = order.orderType == null
        ? null
        : order.orderTypeForInfo
            ? '${order.orderType!} (${AppStrings.accompanyingProduct})'
            : order.orderType!;

    return PrintableDocument(
      title: AppStrings.printOrderTitle,
      subtitle: _printNumberLabel(order.orderNumber),
      warehouseId: order.outletId,
      fields: [
        if (order.createdDateDisplay != null)
          PrintableField(
            label: AppStrings.createdDate,
            value: order.createdDateDisplay!,
          ),
        if (orderTypeLabel != null)
          PrintableField(label: AppStrings.orderType, value: orderTypeLabel),
        if (order.organization != null)
          PrintableField(
            label: AppStrings.organizationSender,
            value: order.organization!,
          ),
        if (order.warehouseName != null)
          PrintableField(
            label: AppStrings.warehouseSender,
            value: order.warehouseName!,
          ),
        if (order.recipientOrganization != null)
          PrintableField(
            label: AppStrings.recipient,
            value: order.recipientOrganization!,
          ),
        if (order.recipientWarehouse != null)
          PrintableField(
            label: AppStrings.recipientWarehouse,
            value: order.recipientWarehouse!,
          ),
        ..._authorField(
          documentId: order.id,
          authorLogin: order.authorLogin,
          author: order.author,
        ),
        PrintableField(
          label: AppStrings.shipmentDate,
          value: order.deliveryDateDisplay ?? _formatDate(order.deliveryDate),
        ),
        PrintableField(
          label: AppStrings.comment,
          value: _commentValue(order.comment),
        ),
      ],
      items: visibleItems,
    );
  }

  static PrintableDocument fromTransfer(InternalTransfer transfer) {
    return PrintableDocument(
      title: AppStrings.printTransferTitle,
      subtitle: _printNumberLabel(transfer.number),
      warehouseId: transfer.recipientWarehouseId,
      fields: [
        PrintableField(
          label: AppStrings.date,
          value: transfer.dateDisplay ?? _formatDate(transfer.date),
        ),
        PrintableField(
          label: AppStrings.organization,
          value: transfer.organizationName,
        ),
        PrintableField(
          label: AppStrings.warehouseSender,
          value: transfer.senderWarehouseName,
        ),
        PrintableField(
          label: AppStrings.recipientWarehouse,
          value: transfer.recipientWarehouseName,
        ),
        ..._authorField(
          documentId: transfer.id,
          authorLogin: transfer.authorLogin,
          author: transfer.author,
        ),
        if (transfer.comment != null)
          PrintableField(
            label: AppStrings.comment,
            value: transfer.comment!.trim(),
          ),
      ],
      items: transfer.items
          .map(
            (item) => PrintableItem(
              name: item.name,
              quantityLabel: _quantityLabel(item.quantity, item.unit),
              code: productCodeDisplayLabel(item.code ?? ''),
            ),
          )
          .toList(),
    );
  }

  static PrintableDocument fromInventory(InventoryDocument document) {
    return PrintableDocument(
      title: AppStrings.printInventoryTitle,
      subtitle: _printNumberLabel(document.number),
      warehouseId: document.warehouseId,
      fields: [
        PrintableField(
          label: AppStrings.date,
          value: document.dateDisplay ?? _formatDate(document.date),
        ),
        PrintableField(
          label: AppStrings.organization,
          value: document.organizationName,
        ),
        PrintableField(
          label: AppStrings.warehouse,
          value: document.warehouseName,
        ),
        ..._authorField(
          documentId: document.id,
          authorLogin: document.authorLogin,
          author: document.author,
        ),
        if (document.comment != null)
          PrintableField(
            label: AppStrings.comment,
            value: document.comment!.trim(),
          ),
      ],
      items: document.items
          .map(
            (item) => PrintableItem(
              name: item.name,
              quantityLabel: item.hasAccountingQuantity
                  ? '${AppStrings.actualQuantity}: ${_quantityLabel(item.quantity, item.unit)}; '
                      '${AppStrings.accountingQuantity}: '
                      '${_quantityLabel(item.accountingQuantity!, item.unit)}'
                  : _quantityLabel(item.quantity, item.unit),
              code: productCodeDisplayLabel(item.code ?? ''),
            ),
          )
          .toList(),
    );
  }

  static PrintableDocument fromWriteoff(StockWriteoff writeoff) {
    return PrintableDocument(
      title: AppStrings.printWriteoffTitle,
      subtitle: _printNumberLabel(writeoff.number),
      warehouseId: writeoff.warehouseId,
      fields: [
        PrintableField(
          label: AppStrings.date,
          value: writeoff.dateDisplay ?? _formatDate(writeoff.date),
        ),
        PrintableField(
          label: AppStrings.organization,
          value: writeoff.organizationName,
        ),
        PrintableField(
          label: AppStrings.warehouse,
          value: writeoff.warehouseName,
        ),
        if (writeoff.reasonName != null)
          PrintableField(
            label: AppStrings.writeoffReason,
            value: writeoff.reasonName!.trim(),
          ),
        ..._authorField(
          documentId: writeoff.id,
          authorLogin: writeoff.authorLogin,
          author: writeoff.author,
        ),
        if (writeoff.comment != null)
          PrintableField(
            label: AppStrings.comment,
            value: writeoff.comment!.trim(),
          ),
      ],
      items: writeoff.items
          .map(
            (item) => PrintableItem(
              name: item.name,
              quantityLabel: _quantityLabel(item.quantity, item.unit),
              code: productCodeDisplayLabel(item.code ?? ''),
            ),
          )
          .toList(),
    );
  }

  static PrintableDocument fromProduction(ProductionDocument document) {
    return PrintableDocument(
      title: AppStrings.printProductionTitle,
      subtitle: _printNumberLabel(document.number),
      warehouseId: document.warehouseId,
      fields: [
        PrintableField(
          label: AppStrings.date,
          value: document.dateDisplay ?? _formatDate(document.date),
        ),
        PrintableField(
          label: AppStrings.organization,
          value: document.organizationName,
        ),
        PrintableField(
          label: AppStrings.productionWarehouse,
          value: document.warehouseName,
        ),
        if (document.rawMaterialsWarehouseName != null)
          PrintableField(
            label: AppStrings.rawMaterialsWarehouse,
            value: document.rawMaterialsWarehouseName!.trim(),
          ),
        ..._authorField(
          documentId: document.id,
          authorLogin: document.authorLogin,
          author: document.author,
        ),
        if (document.comment != null)
          PrintableField(
            label: AppStrings.comment,
            value: document.comment!.trim(),
          ),
      ],
      items: document.items
          .map(
            (item) => PrintableItem(
              name: item.name,
              quantityLabel: _quantityLabel(item.quantity, item.unit),
              code: productCodeDisplayLabel(item.code ?? ''),
            ),
          )
          .toList(),
    );
  }

  static List<PrintableField> _authorField({
    required String documentId,
    String? authorLogin,
    String? author,
  }) {
    final login = DocumentAuthorSupport.resolveLogin(
      documentId: documentId,
      authorLogin: authorLogin,
      author: author,
    );
    if (login == null || login.isEmpty) return const [];
    return [PrintableField(label: AppStrings.author, value: login)];
  }

  static String _printNumberLabel(String number) {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return '№ —';
    if (trimmed.startsWith('№')) return trimmed;
    return '№ $trimmed';
  }

  static String _commentValue(String? comment) {
    final trimmed = comment?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return AppStrings.noComment;
  }

  static PrintableItem? _mapOrderItem(OrderItem item) {
    final name = orderItemDisplayName(item.name);
    if (name == null) return null;
    return PrintableItem(
      name: name,
      quantityLabel: item.quantityLabel,
    );
  }

  static String _quantityLabel(double quantity, String? unit) {
    final qty = formatQuantityForInput(quantity);
    if (unit != null && unit.trim().isNotEmpty) {
      return '$qty ${unit.trim()}';
    }
    return qty;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}
