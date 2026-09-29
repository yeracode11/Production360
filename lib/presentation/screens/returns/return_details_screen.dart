import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/return_document.dart';
import '../../../domain/repositories/return_repository.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../../widgets/document_author_row.dart';

class ReturnDetailsScreen extends StatefulWidget {
  const ReturnDetailsScreen({
    super.key,
    required this.returnId,
    this.embedded = false,
  });

  final String returnId;
  final bool embedded;

  @override
  State<ReturnDetailsScreen> createState() => _ReturnDetailsScreenState();
}

class _ReturnDetailsScreenState extends State<ReturnDetailsScreen> {
  ReturnDocument? _returnDocument;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReturn();
  }

  Future<void> _loadReturn() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final doc =
          await sl<ReturnRepository>().getReturnById(widget.returnId);
      if (!mounted) return;
      if (doc == null) {
        setState(() {
          _loadError = AppStrings.returnNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _returnDocument = doc;
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
                onRefresh: _loadReturn,
                child: _buildContent(),
              );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: AppStrings.returnDetailsTitle,
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
                    onPressed: _loadReturn,
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
    final doc = _returnDocument!;

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
                  label: AppStrings.returnNumber,
                  value: doc.number,
                ),
                _DetailRow(
                  label: AppStrings.sender,
                  value: doc.senderWarehouseDisplay,
                ),
                if (doc.recipientWarehouseDisplay.isNotEmpty)
                  _DetailRow(
                    label: AppStrings.recipient,
                    value: doc.recipientWarehouseDisplay,
                  ),
                if (doc.documentSum != null)
                  _DetailRow(
                    label: AppStrings.documentSum,
                    value: formatTengeAmount(doc.documentSum),
                  ),
                ResolvedDocumentAuthorRow(
                  documentId: doc.id,
                  authorLogin: doc.authorLogin,
                  author: doc.author,
                ),
                if (doc.comment != null && doc.comment!.isNotEmpty)
                  _DetailRow(
                    label: AppStrings.comment,
                    value: doc.comment!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.returnItems,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (doc.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              AppStrings.noReturnItems,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ...doc.items.map((item) {
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
                    if (item.price != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.itemPrice}: ${formatTengeAmount(item.price)}',
                      ),
                    ],
                    if (item.sum != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.itemSum}: ${formatTengeAmount(item.sum)}',
                      ),
                    ],
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
            width: 160,
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
