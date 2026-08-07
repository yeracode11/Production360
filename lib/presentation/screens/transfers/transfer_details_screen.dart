import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../widgets/document_author_row.dart';
import '../../../domain/entities/internal_transfer.dart';
import '../../../domain/repositories/transfer_repository.dart';
import '../../../domain/services/document_print_mapper.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/print_document_button.dart';

class TransferDetailsScreen extends StatefulWidget {
  const TransferDetailsScreen({
    super.key,
    required this.transferId,
    this.embedded = false,
  });

  final String transferId;
  final bool embedded;

  @override
  State<TransferDetailsScreen> createState() => _TransferDetailsScreenState();
}

class _TransferDetailsScreenState extends State<TransferDetailsScreen> {
  InternalTransfer? _transfer;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadTransfer();
  }

  Future<void> _loadTransfer() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final transfer =
          await sl<TransferRepository>().getTransferById(widget.transferId);
      if (!mounted) return;
      if (transfer == null) {
        setState(() {
          _loadError = AppStrings.transferNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _transfer = transfer;
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
                onRefresh: _loadTransfer,
                child: _buildContent(),
              );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: AppStrings.transferDetailsTitle,
        actions: [
          if (!_isLoading && _loadError == null && _transfer != null)
            PrintDocumentButton(
              document: DocumentPrintMapper.fromTransfer(_transfer!),
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
                    onPressed: _loadTransfer,
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
    final transfer = _transfer!;

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
                  label: AppStrings.transferNumber,
                  value: transfer.number,
                ),
                _DetailRow(
                  label: AppStrings.date,
                  value: transfer.dateDisplay ??
                      '${transfer.date.day.toString().padLeft(2, '0')}.'
                          '${transfer.date.month.toString().padLeft(2, '0')}.'
                          '${transfer.date.year}',
                ),
                _DetailRow(
                  label: AppStrings.organization,
                  value: transfer.organizationName,
                ),
                _DetailRow(
                  label: AppStrings.warehouseSender,
                  value: transfer.senderWarehouseName,
                ),
                _DetailRow(
                  label: AppStrings.recipientWarehouse,
                  value: transfer.recipientWarehouseName,
                ),
                ResolvedDocumentAuthorRow(
                  documentId: transfer.id,
                  authorLogin: transfer.authorLogin,
                  author: transfer.author,
                ),
                if (transfer.comment != null)
                  _DetailRow(
                    label: AppStrings.comment,
                    value: transfer.comment!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.transferItems,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (transfer.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppStrings.noTransferItems,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...transfer.items.map((item) {
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
