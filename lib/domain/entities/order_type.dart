import 'package:equatable/equatable.dart';

/// Order request type from 1C «ТипыЗаявок».
class OrderType extends Equatable {
  const OrderType({
    required this.uid,
    required this.name,
  });

  final String uid;
  final String name;

  @override
  List<Object?> get props => [uid, name];
}
