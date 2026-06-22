import 'package:equatable/equatable.dart';

/// Warehouse (склад) from 1C «Склады» array.
class Warehouse extends Equatable {
  const Warehouse({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
