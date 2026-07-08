import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_writeoff_result.dart';

class CreateWriteoffResultModel extends CreateWriteoffResult {
  const CreateWriteoffResultModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    super.dateDisplay,
  });

  factory CreateWriteoffResultModel.from1CJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return CreateWriteoffResultModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
    );
  }
}
