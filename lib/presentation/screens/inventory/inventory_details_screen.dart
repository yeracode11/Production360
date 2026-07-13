import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../domain/entities/inventory_document.dart';
import '../../../domain/repositories/inventory_repository.dart';

class InventoryDetailsScreen extends StatefulWidget {
  const InventoryDetailsScreen({super.key, required this.inventoryId});

  final String inventoryId;

  @override
  State<InventoryDetailsScreen> createState() => _InventoryDetailsScreenState();
}

class _InventoryDetailsScreenState extends State<InventoryDetailsScreen> {
  InventoryDocument? _document;
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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.inventoryDetailsTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadDocument,
                  child: _buildContent(),
                ),
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
                  label: AppStrings.status,
                  value: document.isPosted
                      ? AppStrings.inventoryPosted
                      : AppStrings.inventoryNotPosted,
                ),
                _DetailRow(
                  label: AppStrings.organization,
                  value: document.organizationName,
                ),
                _DetailRow(
                  label: AppStrings.warehouse,
                  value: document.warehouseName,
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
        if (document.items.isEmpty)
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
