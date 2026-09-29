import '../../domain/entities/return_predata.dart';

class ReturnPredataModel extends ReturnPredata {
  const ReturnPredataModel({
    required super.organizationId,
    required super.organizationName,
    required super.incomingInvoices,
  });

  factory ReturnPredataModel.from1CJson(Map<String, dynamic> json) {
    final invoicesJson = json['ПриходныеНакладные'] as List<dynamic>? ?? [];
    return ReturnPredataModel(
      organizationId: json['ОрганизацияСсылка'] as String? ?? '',
      organizationName: json['ОрганизацияНаименование'] as String? ?? '',
      incomingInvoices: invoicesJson
          .map(
            (e) => IncomingInvoiceSummaryModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class IncomingInvoiceSummaryModel extends IncomingInvoiceSummary {
  const IncomingInvoiceSummaryModel({
    required super.id,
    required super.date,
    required super.number,
    required super.senderOrganizationName,
    required super.senderWarehouseName,
    required super.productsText,
  });

  factory IncomingInvoiceSummaryModel.from1CJson(Map<String, dynamic> json) {
    return IncomingInvoiceSummaryModel(
      id: json['docID'] as String? ?? json['Ссылка'] as String? ?? '',
      date: json['Дата'] as String? ?? '',
      number: json['Номер'] as String? ?? '',
      senderOrganizationName:
          json['ОрганизацияОтправительНаименование'] as String? ?? '',
      senderWarehouseName:
          json['СкладОтправительНаименование'] as String? ?? '',
      productsText: json['ТекстТовары'] as String? ?? '',
    );
  }
}
