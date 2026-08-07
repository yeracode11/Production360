import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/printer_log.dart';

Future<void> showPrinterLogDialog(
  BuildContext context, {
  required String title,
  String? message,
}) {
  final lines = PrinterLog.recentLines;
  final body = StringBuffer();
  if (message != null && message.isNotEmpty) {
    body.writeln(message);
    body.writeln();
  }
  if (lines.isEmpty) {
    body.write(AppStrings.printerLogEmpty);
  } else {
    body.write(lines.join('\n'));
  }

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(
          body.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.35,
              ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: body.toString()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.printerLogCopied)),
            );
          },
          child: const Text(AppStrings.printerLogCopy),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.close),
        ),
      ],
    ),
  );
}
