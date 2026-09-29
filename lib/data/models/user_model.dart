import '../../domain/entities/user.dart';
import 'warehouse_model.dart';

class UserModel extends User {
  const UserModel({
    required super.username,
    required super.uid,
    required super.warehouses,
    super.roles,
  });

  /// Parses 1C authentication response JSON.
  factory UserModel.from1CJson(Map<String, dynamic> json) {
    List<String>? roles;
    if (json.containsKey('roles')) {
      final raw = json['roles'];
      if (raw is List) {
        roles = raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        roles = const [];
      }
    }

    return UserModel(
      username: json['ИмяПользователя'] as String,
      uid: json['УИДПользователя'] as String,
      warehouses: (json['Склады'] as List<dynamic>?)
              ?.map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      roles: roles,
    );
  }

  Map<String, dynamic> to1CJson() => {
        'ИмяПользователя': username,
        'УИДПользователя': uid,
        'Склады': warehouses
            .map((w) => (w as WarehouseModel).toJson())
            .toList(),
        if (roles != null) 'roles': roles,
      };
}
