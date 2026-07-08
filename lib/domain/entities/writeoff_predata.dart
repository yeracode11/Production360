import 'package:equatable/equatable.dart';

/// GET /mobile/spisaniyezapasov/predata
class WriteoffPredata extends Equatable {
  const WriteoffPredata({
    required this.organizationId,
    required this.organizationName,
    this.availableReasons = const [],
  });

  final String organizationId;
  final String organizationName;
  final List<WriteoffReasonOption> availableReasons;

  @override
  List<Object?> get props => [
        organizationId,
        organizationName,
        availableReasons,
      ];
}

class WriteoffReasonOption extends Equatable {
  const WriteoffReasonOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
