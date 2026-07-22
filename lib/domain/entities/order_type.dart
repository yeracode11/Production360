import 'package:equatable/equatable.dart';

/// Order request type from 1C «ТипыЗаявок».
class OrderType extends Equatable {
  const OrderType({
    required this.uid,
    required this.name,
    this.forInfo = false,
  });

  final String uid;
  final String name;
  /// Сопутствующий товар (`forInfo` из 1С).
  final bool forInfo;

  @override
  List<Object?> get props => [uid, name, forInfo];
}
