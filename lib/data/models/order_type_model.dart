import '../../core/utils/one_c_bool.dart';
import '../../domain/entities/order_type.dart';

class OrderTypeModel extends OrderType {
  const OrderTypeModel({
    required super.uid,
    required super.name,
    super.forInfo,
  });

  factory OrderTypeModel.from1CJson(Map<String, dynamic> json) {
    return OrderTypeModel(
      uid: json['УИД'] as String,
      name: json['Наименование'] as String,
      forInfo: parseOneCBool(json['forInfo']),
    );
  }

  Map<String, dynamic> to1CJson() => {
        'УИД': uid,
        'Наименование': name,
        'forInfo': forInfo,
      };
}
