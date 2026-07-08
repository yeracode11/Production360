import '../../domain/entities/writeoff_predata.dart';

class WriteoffPredataModel extends WriteoffPredata {
  const WriteoffPredataModel({
    required super.organizationId,
    required super.organizationName,
    super.availableReasons = const [],
  });

  factory WriteoffPredataModel.from1CJson(Map<String, dynamic> json) {
    final reasonsJson = json['ПричиныСписания'] as List<dynamic>? ?? [];
    return WriteoffPredataModel(
      organizationId: json['ОрганизацияСсылка'] as String,
      organizationName: json['ОрганизацияНаименование'] as String,
      availableReasons: reasonsJson
          .map(
            (e) => WriteoffReasonOptionModel.from1CJson(
              e as Map<String, dynamic>,
            ),
          )
          .where((r) => r.id.isNotEmpty)
          .toList(),
    );
  }
}

class WriteoffReasonOptionModel extends WriteoffReasonOption {
  const WriteoffReasonOptionModel({
    required super.id,
    required super.name,
  });

  factory WriteoffReasonOptionModel.from1CJson(Map<String, dynamic> json) {
    return WriteoffReasonOptionModel(
      id: (json['ПричинаСписанияСсылка'] as String?)?.trim() ?? '',
      name: (json['ПричинаСписанияНаименование'] as String?)?.trim() ?? '',
    );
  }
}
