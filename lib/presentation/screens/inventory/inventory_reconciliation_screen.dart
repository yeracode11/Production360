import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/storage/inventory_completed_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/inventory_document.dart';
import '../../../domain/repositories/inventory_repository.dart';
import '../../bloc/inventory/inventory_cubit.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../../widgets/inventory_mismatch_ui.dart';
import '../../widgets/inventory_reconciliation_dialog.dart';

/// Экран сверки учётного и фактического количества после создания документа.
class InventoryReconciliationScreen extends StatefulWidget {
  const InventoryReconciliationScreen({
    super.key,
    required this.inventoryId,
    this.actualQuantitiesByProductId,
    this.openedAfterCreate = false,
  });

  final String inventoryId;
  final Map<String, double>? actualQuantitiesByProductId;
  final bool openedAfterCreate;

  @override
  State<InventoryReconciliationScreen> createState() =>
      _InventoryReconciliationScreenState();
}

class _InventoryReconciliationScreenState
    extends State<InventoryReconciliationScreen> {
  InventoryDocument? _document;
  List<InventoryReconciliationLine> _lines = const [];
  bool _isLoading = true;
  String? _loadError;
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
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

      if (widget.openedAfterCreate) {
        _document = document;
        await _finishAndExit();
        return;
      }

      setState(() {
        _document = document;
        _lines = _buildLines(document);
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

  List<InventoryReconciliationLine> _buildLines(InventoryDocument document) {
    final overrides = widget.actualQuantitiesByProductId;
    return document.items.map((item) {
      final actual = overrides?[item.productId] ?? item.quantity;
      return InventoryReconciliationLine(
        name: item.name,
        code: item.code,
        unit: item.unit,
        accountingQuantity: item.accountingQuantity,
        actualQuantity: actual,
      );
    }).toList();
  }

  Future<void> _finishAndExit() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await sl<InventoryCompletedStorage>().markCompleted(widget.inventoryId);

    if (!mounted) return;
    context.read<InventoryCubit>().refreshCurrentWarehouse();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: AppStrings.inventoryReconciliationTitle,
      ),
      body: DesktopContentConstraint(
        child: Stack(
          children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? _buildError()
                  : _buildContent(),
          if (_isFinishing)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
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
    );
  }

  Widget _buildContent() {
    final document = _document!;
    final mismatchCount = _lines.where((line) => line.hasMismatch).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.inventoryNumber}${document.number}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  document.warehouseName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                if (widget.openedAfterCreate) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.inventoryReconciliationAfterCreateHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (mismatchCount > 0)
          InventoryMismatchBanner(mismatchCount: mismatchCount)
        else
          const InventoryMatchBanner(),
        const SizedBox(height: 12),
        ..._lines.map(
          (line) => InventoryReconciliationRowCard(line: line),
        ),
      ],
    );
  }
}

/// Карточка строки сверки.
class InventoryReconciliationRowCard extends StatelessWidget {
  const InventoryReconciliationRowCard({super.key, required this.line});

  final InventoryReconciliationLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final unitSuffix =
        line.unit != null && line.unit!.isNotEmpty ? ' ${line.unit}' : '';
    final accounting = line.accountingQuantity;
    final difference = line.difference;
    final codeLabel = productCodeDisplayLabel(line.code ?? '');
    final hasMismatch = line.hasMismatch;

    return InventoryMismatchCard(
      hasMismatch: hasMismatch,
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
                    line.name,
                    style: theme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: hasMismatch
                          ? AppColors.mismatchText
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasMismatch) ...[
                  const SizedBox(width: 8),
                  const InventoryMismatchBadge(),
                ],
              ],
            ),
            if (codeLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                codeLabel,
                style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 10),
            _ValueRow(
              label: AppStrings.accountingQuantity,
              value: accounting == null
                  ? '—'
                  : '${formatQuantityForInput(accounting)}$unitSuffix',
            ),
            const SizedBox(height: 6),
            _ValueRow(
              label: AppStrings.actualQuantity,
              value: '${formatQuantityForInput(line.actualQuantity)}$unitSuffix',
              emphasized: true,
              valueColor: hasMismatch ? AppColors.mismatchText : null,
            ),
            if (difference != null && hasMismatch)
              InventoryDifferenceHighlight(
                label: AppStrings.quantityDifference,
                value:
                    '${difference > 0 ? '+' : ''}${formatQuantityForInput(difference)}$unitSuffix',
              ),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasized;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: (emphasized ? theme.bodyMedium : theme.bodySmall)?.copyWith(
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
