import 'package:equatable/equatable.dart';

enum AppStatus { normal, updateRequired }

class UpdateState extends Equatable {
  const UpdateState({required this.status});

  const UpdateState.normal() : status = AppStatus.normal;

  const UpdateState.updateRequired() : status = AppStatus.updateRequired;

  final AppStatus status;

  @override
  List<Object?> get props => [status];
}
