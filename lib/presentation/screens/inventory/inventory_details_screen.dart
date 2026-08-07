import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/inventory_completed_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/inventory_quantity.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../domain/entities/inventory_document.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../../domain/services/document_print_mapper.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/document_screen_scaffold.dart';
import '../../widgets/inventory_mismatch_ui.dart';
import '../../widgets/on_screen_keyboard/on_screen_keyboard_field.dart';
import '../../widgets/print_document_button.dart';

class InventoryDetailsScreen extends StatefulWidget {
  const InventoryDetailsScreen({
    super.key,
    required this.inventoryId,
    this.embedded = false,
  });

  final String inventoryId;
  final bool embedded;

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  InventoryDocument? _document;
  List<_InventoryItemRow> _rows = [];
  bool _isLoading = true;
  String? _loadError;
  late bool _locallyCompleted;

  bool get _canEdit =>
      _document != null && !_document!.isPosted && !_locallyCompleted;

  @override
  void initState() {
    super.initState();
    _locallyCompleted =
        sl<InventoryCompletedStorage>().isCompleted(widget.inventoryId);
    _loadDocument();
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  void _disposeRows() {
    for (final row in _rows) {
      row.dispose();
    }
    _rows = [];
  }

  void _initRows(InventoryDocument document) {
    _disposeRows();
    _rows = document.items
        .map((item) => _InventoryItemRow.fromItem(item, editable: !document.isPosted))
        .toList();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final document = await sl<InventoryRepository>()
          .getInventoryById(widget.inventoryId);
      if (!mounted) return;
      if (document == null) {
        setState(() {
          _loadError = AppStrings.inventoryNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _document = document;
        if (document.isPosted) {
          _locallyCompleted = true;
        }
        _initRows(document);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = exceptionMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
            ? _buildError()
            : RefreshIndicator(
                onRefresh: _loadDocument,
                child: _buildContent(),
              );

    if (widget.embedded) return body;

    return DocumentScreenScaffold(
      title: AppStrings.inventoryDetailsTitle,
      actions: [
        if (!_isLoading && _loadError == null && _document != null)
          PrintDocumentButton(
            document: DocumentPrintMapper.fromInventory(_document!),
          ),
      ],
      body: body,
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.4,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _loadError!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadDocument,
                    child: const Text(AppStrings.pullToRefresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final document = _document!;

    return DismissKeyboard.onTap(
      context,
      Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.mainInfo,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: AppStrings.inventoryNumber,
                      value: document.number,
                    ),
                    _DetailRow(
                      label: AppStrings.date,
                      value: document.dateDisplay ??
                          '${document.date.day.toString().padLeft(2, '0')}.'
                              '${document.date.month.toString().padLeft(2, '0')}.'
                              '${document.date.year}',
                    ),
                    _DetailRow(
                      label: AppStrings.organization,
                      value: document.organizationName,
                    ),
                    _DetailRow(
                      label: AppStrings.warehouse,
                      value: document.warehouseName,
                    ),
                    ResolvedDocumentAuthorRow(
                      documentId: document.id,
                      authorLogin: document.authorLogin,
                      author: document.author,
                    ),
                    if (document.comment != null)
                      _DetailRow(
                        label: AppStrings.comment,
                        value: document.comment!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppStrings.inventoryItems,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  AppStrings.noInventoryItems,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              )
            else
              ..._rows.map(
                (row) => _InventoryItemCard(
                  row: row,
                  editable: _canEdit,
                  onChanged: () => setState(() {}),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InventoryItemRow {
  _InventoryItemRow({
    required this.item,
    required this.quantityController,
  });

  factory _InventoryItemRow.fromItem(
    InventoryDocumentItem item, {
    required bool editable,
  }) {
    return _InventoryItemRow(
      item: item,
      quantityController: TextEditingController(
        text: formatQuantityForInput(item.quantity),
      ),
    );
  }

  final InventoryDocumentItem item;
  final TextEditingController quantityController;

  bool get hasMismatch {
    final actual = parseAmount(quantityController.text.trim());
    if (actual == null) return false;
    return InventoryQuantity.mismatches(
      actual.toDouble(),
      item.accountingQuantity,
    );
  }

  void dispose() {
    quantityController.dispose();
  }
}

class _InventoryItemCard extends StatelessWidget {
  const _InventoryItemCard({
    required this.row,
    required this.editable,
    required this.onChanged,
  });

  final _InventoryItemRow row;
  final bool editable;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final codeLabel = productCodeDisplayLabel(item.code ?? '');
    final unitSuffix =
        item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : '';
    final mismatch = row.hasMismatch;

    return InventoryMismatchCard(
      hasMismatch: mismatch,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: mismatch
                              ? AppColors.mismatchText
                              : AppColors.textPrimary,
                        ),
                  ),
                ),
                if (mismatch) ...[
                  const SizedBox(width: 8),
                  const InventoryMismatchBadge(),
                ],
              ],
            ),
            if (codeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                codeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (item.hasAccountingQuantity) ...[
              const SizedBox(height: 8),
              Text(
                '${AppStrings.accountingQuantity}: '
                '${formatQuantityForInput(item.accountingQuantity!)}$unitSuffix',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            if (editable)
              OnScreenKeyboardTextField(
                controller: row.quantityController,
                decoration: InputDecoration(
                  labelText: AppStrings.actualQuantity,
                  filled: mismatch,
                  fillColor: mismatch
                      ? AppColors.mismatchAccent.withValues(alpha: 0.06)
                      : null,
                  suffix: item.unit != null && item.unit!.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            item.unit!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: mismatch
                                      ? AppColors.mismatchText
                                      : AppColors.turquoiseDark,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: const [QuantityInputFormatter()],
                validator: (value) => validateQuantityInput(
                  value,
                  required: true,
                  allowZero: true,
                ),
                onChanged: (_) => onChanged(),
              )
            else
              Text(
                '${AppStrings.actualQuantity}: '
                '${formatQuantityForInput(item.quantity)}$unitSuffix',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: mismatch
                          ? AppColors.mismatchText
                          : AppColors.textPrimary,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.deepBrownLight,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
