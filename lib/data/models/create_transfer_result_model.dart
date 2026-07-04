import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_transfer_result.dart';

class CreateTransferResultModel extends CreateTransferResult {
  const CreateTransferResultModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    super.dateDisplay,
  });

  factory CreateTransferResultModel.from1CJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return CreateTransferResultModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
    );
  }
}
