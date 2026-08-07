import '../../core/constants/app_strings.dart';
import '../../domain/entities/printable_document.dart';
import 'esc_pos_builder.dart';

/// Формирует ESC/POS байты для документа 80 мм (48 символов, RK1048).
class EscPosPrintService {
  List<int> buildDocumentBytes(PrintableDocument document) {
    final b = EscPosBuilder()..initialize();

    b.setAlign(1);
    b.setBold(true);
    b.setTextSize(doubleWidth: true);
    b.textLine(document.title);
    if (document.subtitle != null && document.subtitle!.trim().isNotEmpty) {
      b.textLine(document.subtitle!.trim());
    }
    b.setBold(false);
    b.setTextSize();
    b.setAlign(0);
    b.newline();

    if (document.fields.isNotEmpty) {
      for (final field in document.fields) {
        b.field(field.label, field.value.trim());
      }
      b.separator();
    }

    if (document.items.isNotEmpty) {
      b.setBold(true);
      b.textLine(AppStrings.printItemsSection);
      b.setBold(false);
      for (var i = 0; i < document.items.length; i++) {
        final item = document.items[i];
        b.textLine('${i + 1}. ${item.name.trim()}');
        if (item.code != null && item.code!.trim().isNotEmpty) {
          b.textLine('   ${item.code!.trim()}');
        }
        b.textLine('   ${item.quantityLabel}');
      }
      b.separator();
    }

    if (document.footer != null && document.footer!.trim().isNotEmpty) {
      b.wrappedText(document.footer!.trim());
      b.separator();
    }

    b.setAlign(1);
    b.textLine(AppStrings.printAppName);
    b.setAlign(0);
    b.feed(4);
    b.cut();

    return b.build();
  }

  List<int> buildTestPageBytes() {
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return buildDocumentBytes(
      PrintableDocument(
        title: AppStrings.printTestTitle,
        warehouseId: '',
        fields: [
          PrintableField(label: AppStrings.date, value: timestamp),
          PrintableField(
            label: AppStrings.printPaperWidth,
            value: AppStrings.printPaperWidthValue,
          ),
          PrintableField(
            label: AppStrings.printKazakhSampleLabel,
            value: AppStrings.printKazakhSampleText,
          ),
        ],
        items: const [
          PrintableItem(
            name: 'Тестовая позиция',
            quantityLabel: '1 шт',
          ),
          PrintableItem(
            name: '+Безе',
            quantityLabel: '1 кг',
          ),
        ],
        footer: AppStrings.printTestFooter,
      ),
    );
  }
}
