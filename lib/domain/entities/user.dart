import 'package:equatable/equatable.dart';

import 'warehouse.dart';

/// Authenticated user from 1C HTTP service.
class User extends Equatable {
  const User({
    required this.username,
    required this.uid,
    required this.warehouses,
    this.roles,
  });

  final String username;
  final String uid;
  final List<Warehouse> warehouses;

  /// `null` — снимок без ролей (до ответа `/mobile/auth`); доступа к разделам нет.
  final List<String>? roles;

  bool canAccessRole(String roleKey) {
    final granted = roles;
    if (granted == null) {
      return false;
    }
    final normalized = roleKey.trim().toLowerCase();
    return granted.any((role) => role.trim().toLowerCase() == normalized);
  }

  @override
  List<Object?> get props => [username, uid, warehouses, roles];
}
