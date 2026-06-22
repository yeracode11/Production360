import 'package:equatable/equatable.dart';

/// Available delivery slot from GET /mobile/zayavka/type/data «dates».
class DeliveryDateOption extends Equatable {
  const DeliveryDateOption({
    required this.value,
    required this.display,
  });

  /// Raw 1C datetime, e.g. «20260613190000».
  final String value;
  final String display;

  @override
  List<Object?> get props => [value, display];
}
