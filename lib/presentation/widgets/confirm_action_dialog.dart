import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Показывает диалог «Вы уверены?» с кнопками «Нет» / «Да».
Future<bool> showConfirmActionDialog(
  BuildContext context, {
  String? message,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text(AppStrings.confirmTitle),
      content: Text(message ?? AppStrings.confirmDefaultMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text(AppStrings.no),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text(AppStrings.yes),
        ),
      ],
    ),
  ).then((value) => value == true);
}
