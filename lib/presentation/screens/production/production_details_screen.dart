import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../widgets/document_author_row.dart';
import '../../../domain/entities/production_document.dart';
import '../../../domain/repositories/production_repository.dart';
import '../../../domain/services/document_print_mapper.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/print_document_button.dart';

class ProductionDetailsScreen extends StatefulWidget {
  const ProductionDetailsScreen({
    super.key,
    required this.productionId,
    this.embedded = false,
  });

  final String productionId;
  final bool embedded;

  @override
  State<ProductionDetailsScreen> createState() =>
      _ProductionDetailsScreenState();
}

class _ProductionDetailsScreenState extends State<ProductionDetailsScreen> {
  ProductionDocument? _document;
  bool _isLoading = true;
  String? _loadError;

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
      final document = await sl<ProductionRepository>()
          .getProductionById(widget.productionId);
      if (!mounted) return;
      if (document == null) {
        setState(() {
          _loadError = AppStrings.productionNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _document = document;
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

    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: AppStrings.productionDetailsTitle,
        actions: [
          if (!_isLoading && _loadError == null && _document != null)
            PrintDocumentButton(
              document: DocumentPrintMapper.fromProduction(_document!),
            ),
        ],
      ),
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
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
                  label: AppStrings.productionNumber,
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
                  label: AppStrings.productionWarehouse,
                  value: document.warehouseName,
                ),
                if (document.rawMaterialsWarehouseName != null)
                  _DetailRow(
                    label: AppStrings.rawMaterialsWarehouse,
                    value: document.rawMaterialsWarehouseName!,
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
          AppStrings.productionItems,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (document.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppStrings.noProductionItems,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...document.items.map((item) {
            final codeLabel = productCodeDisplayLabel(item.code ?? '');
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (codeLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(codeLabel),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.itemQuantity}: ${item.quantity}'
                      '${item.unit != null ? ' ${item.unit}' : ''}',
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
      ],
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
