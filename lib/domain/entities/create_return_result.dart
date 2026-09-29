import 'package:equatable/equatable.dart';

/// Ответ POST /mobile/vozvrat/create при success.
class CreateReturnResult extends Equatable {
  const CreateReturnResult({
    required this.id,
    required this.number,
    required this.date,
    required this.isPosted,
    this.dateDisplay,
  });

  final String id;
  final String number;
  final DateTime date;
  final bool isPosted;
  final String? dateDisplay;

  @override
  List<Object?> get props => [id, number, date, isPosted, dateDisplay];
}
