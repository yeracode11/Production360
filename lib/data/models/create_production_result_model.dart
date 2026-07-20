import '../../core/utils/one_c_date.dart';
import '../../domain/entities/create_production_result.dart';

class CreateProductionResultModel extends CreateProductionResult {
  const CreateProductionResultModel({
    required super.id,
    required super.number,
    required super.date,
    required super.isPosted,
    super.dateDisplay,
  });

  factory CreateProductionResultModel.from1CJson(Map<String, dynamic> json) {
    final dateRaw = json['Дата'] as String;
    return CreateProductionResultModel(
      id: json['Ссылка'] as String,
      number: json['Номер'] as String,
      date: parseOneCDate(dateRaw),
      dateDisplay: dateRaw,
      isPosted: json['Проведен'] as bool? ?? false,
    );
  }
}
