import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Показывает диалог подтверждения с кнопками «Нет» / «Да».
Future<bool> showConfirmActionDialog(
  BuildContext context, {
  String? title,
  String? message,
}) {
  final dialogTitle = title ?? AppStrings.confirmTitle;
  final dialogMessage = message ?? AppStrings.confirmDefaultMessage;
  final showContent = title == null || message != null;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogTitle),
      content: showContent ? Text(dialogMessage) : null,
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
