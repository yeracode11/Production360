import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/entities/printable_document.dart';
import '../screens/print/printer_selection_screen.dart';

class PrintDocumentButton extends StatelessWidget {
  const PrintDocumentButton({super.key, required this.document});

  final PrintableDocument document;

  void _openPrinterSelection(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PrinterSelectionScreen(document: document),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.printDocument,
      onPressed: () => _openPrinterSelection(context),
      icon: const Icon(Icons.print_outlined),
    );
  }
}
