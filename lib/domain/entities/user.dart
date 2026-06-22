import 'package:equatable/equatable.dart';

import 'warehouse.dart';

/// Authenticated user from 1C HTTP service.
class User extends Equatable {
  const User({
    required this.username,
    required this.uid,
    required this.warehouses,
  });

  final String username;
  final String uid;
  final List<Warehouse> warehouses;

  @override
  List<Object?> get props => [username, uid, warehouses];
}
