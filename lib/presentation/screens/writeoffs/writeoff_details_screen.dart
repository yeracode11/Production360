import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../widgets/document_author_row.dart';
import '../../../domain/entities/stock_writeoff.dart';
import '../../../domain/repositories/writeoff_repository.dart';
import '../../../domain/services/document_print_mapper.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../../widgets/print_document_button.dart';

class WriteoffDetailsScreen extends StatefulWidget {
  const WriteoffDetailsScreen({
    super.key,
    required this.writeoffId,
    this.embedded = false,
  });

  final String writeoffId;
  final bool embedded;

  @override
  State<WriteoffDetailsScreen> createState() => _WriteoffDetailsScreenState();
}

class _WriteoffDetailsScreenState extends State<WriteoffDetailsScreen> {
  StockWriteoff? _writeoff;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadWriteoff();
  }

  Future<void> _loadWriteoff() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final writeoff =
          await sl<WriteoffRepository>().getWriteoffById(widget.writeoffId);
      if (!mounted) return;
      if (writeoff == null) {
        setState(() {
          _loadError = AppStrings.writeoffNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _writeoff = writeoff;
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
                onRefresh: _loadWriteoff,
                child: _buildContent(),
              );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: AppStrings.writeoffDetailsTitle,
        actions: [
          if (!_isLoading && _loadError == null && _writeoff != null)
            PrintDocumentButton(
              document: DocumentPrintMapper.fromWriteoff(_writeoff!),
            ),
        ],
      ),
      body: DesktopContentConstraint(child: body),
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
                    onPressed: _loadWriteoff,
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
    final writeoff = _writeoff!;

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
                  label: AppStrings.writeoffNumber,
                  value: writeoff.number,
                ),
                _DetailRow(
                  label: AppStrings.date,
                  value: writeoff.dateDisplay ??
                      '${writeoff.date.day.toString().padLeft(2, '0')}.'
                          '${writeoff.date.month.toString().padLeft(2, '0')}.'
                          '${writeoff.date.year}',
                ),
                _DetailRow(
                  label: AppStrings.organization,
                  value: writeoff.organizationName,
                ),
                _DetailRow(
                  label: AppStrings.warehouse,
                  value: writeoff.warehouseName,
                ),
                if (writeoff.reasonName != null)
                  _DetailRow(
                    label: AppStrings.writeoffReason,
                    value: writeoff.reasonName!,
                  ),
                ResolvedDocumentAuthorRow(
                  documentId: writeoff.id,
                  authorLogin: writeoff.authorLogin,
                  author: writeoff.author,
                ),
                if (writeoff.comment != null)
                  _DetailRow(
                    label: AppStrings.comment,
                    value: writeoff.comment!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.writeoffItems,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (writeoff.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppStrings.noWriteoffItems,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...writeoff.items.map((item) {
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
