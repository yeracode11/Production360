import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/amount_parser.dart';
import '../../../core/utils/exception_message.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/utils/quantity_input.dart';
import '../../../domain/entities/create_return_request.dart';
import '../../../domain/entities/incoming_invoice.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/return_repository.dart';
import '../../bloc/returns/returns_cubit.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../../widgets/document_author_row.dart';
import '../../widgets/document_screen_scaffold.dart';
import '../../widgets/on_screen_keyboard/on_screen_keyboard_field.dart';
import 'return_details_screen.dart';

class IncomingInvoiceScreen extends StatefulWidget {
  const IncomingInvoiceScreen({
    super.key,
    required this.invoiceId,
    this.invoiceFuture,
    this.embedded = false,
    this.createMode = false,
    this.warehouse,
  });

  final String invoiceId;
  final Future<IncomingInvoice?>? invoiceFuture;
  final bool embedded;
  final bool createMode;
  final Warehouse? warehouse;

  @override
  State<IncomingInvoiceScreen> createState() => _IncomingInvoiceScreenState();
}

class _IncomingInvoiceScreenState extends State<IncomingInvoiceScreen> {
  final _repository = sl<ReturnRepository>();
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  IncomingInvoice? _invoice;
  final List<_ReturnLineRow> _lines = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _createdReturnId;

  bool get _canCreate => widget.createMode && widget.warehouse != null;

  @override
  void initState() {
    super.initState();
    _invoice = _repository.peekCachedIncomingInvoice(widget.invoiceId);
    if (_invoice != null) {
      _isLoading = false;
      _initLinesFromInvoice(_invoice!);
    }
    _loadInvoice(showLoader: _invoice == null);
  }

  @override
  void dispose() {
    _commentController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  void _initLinesFromInvoice(IncomingInvoice invoice) {
    for (final line in _lines) {
      line.dispose();
    }
    _lines
      ..clear()
      ..addAll(
        invoice.items.map(
          (item) => _ReturnLineRow(
            item: item,
            quantityText: widget.createMode
                ? '0'
                : formatQuantityForInput(item.quantity),
          ),
        ),
      );
  }

  Future<void> _loadInvoice({
    bool showLoader = true,
    bool forceRefresh = false,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = _invoice == null;
        _loadError = null;
      });
    }

    try {
      final invoice = await (widget.invoiceFuture ??
          _repository.getIncomingInvoiceById(
            widget.invoiceId,
            forceRefresh: forceRefresh,
            warehouseId: widget.warehouse?.id,
            warehouseName: widget.warehouse?.name,
          ));
      if (!mounted) return;
      if (invoice == null) {
        setState(() {
          _loadError = AppStrings.incomingInvoiceNotFound;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _invoice = invoice;
        _isLoading = false;
        if (_canCreate) {
          _initLinesFromInvoice(invoice);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_invoice == null) {
          _loadError = exceptionMessage(e);
        }
        _isLoading = false;
      });
    }
  }

  double _resolvePrice(IncomingInvoiceItem item) {
    if (item.price != null) return item.price!;
    if (item.sum != null && item.quantity > 0) {
      return item.sum! / item.quantity;
    }
    return 0;
  }

  String? _validateReturnQuantity(String? value, IncomingInvoiceItem item) {
    if (value == null || value.trim().isEmpty) return null;

    final quantity = parseAmount(value.trim());
    if (quantity == null) {
      return AppStrings.itemQuantityInvalid;
    }
    if (quantity <= 0) return null;

    final baseError = validateQuantityInput(value, allowZero: false);
    if (baseError != null) return baseError;

    if (quantity > item.quantity) {
      return '${AppStrings.itemQuantityInvalid} (макс. ${formatQuantityForInput(item.quantity)})';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_canCreate || _invoice == null) return;
    if (!_formKey.currentState!.validate()) return;

    final items = <CreateReturnItemRequest>[];
    for (final line in _lines) {
      final quantity = parseAmount(line.quantityController.text);
      if (quantity == null || quantity <= 0) continue;

      final item = line.item;
      if (item.unitId == null || item.unitId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.itemQuantityInvalid}: ${item.name}'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final price = _resolvePrice(item);
      items.add(
        CreateReturnItemRequest(
          productId: item.productId,
          unitId: item.unitId!,
          quantity: quantity.toDouble(),
          price: price,
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.atLeastOneItem)),
      );
      return;
    }

    final confirmed = await showConfirmActionDialog(
      context,
      title: AppStrings.confirmCreateReturn,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final result = await _repository.createReturn(
        CreateReturnRequest(
          warehouseId: widget.warehouse!.id,
          incomingInvoiceId: widget.invoiceId,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          items: items,
        ),
      );

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      context.read<ReturnsCubit>().refreshCurrentWarehouse();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.returnCreated}: ${result.number}'),
        ),
      );
      setState(() => _createdReturnId = result.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exceptionMessage(e)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdReturnId != null) {
      final details = ReturnDetailsScreen(
        returnId: _createdReturnId!,
        embedded: true,
      );
      if (widget.embedded) return details;
      return DocumentScreenScaffold(
        title: AppStrings.returnDetailsTitle,
        body: details,
      );
    }

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
            ? _buildError()
            : _canCreate
                ? _buildCreateForm()
                : RefreshIndicator(
                    onRefresh: () => _loadInvoice(forceRefresh: true),
                    child: _buildViewContent(),
                  );

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBarWithKeyboard(
        title: widget.createMode
            ? AppStrings.createReturnTitle
            : AppStrings.incomingInvoiceTitle,
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
                    onPressed: () => _loadInvoice(forceRefresh: true),
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

  Widget _buildCreateForm() {
    final invoice = _invoice!;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._buildHeaderCards(invoice),
                const SizedBox(height: 16),
                OnScreenKeyboardTextField(
                  controller: _commentController,
                  maxLines: null,
                  minLines: 2,
                  decoration: const InputDecoration(
                    labelText: AppStrings.comment,
                    hintText: AppStrings.commentHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.returnItems,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_lines.isEmpty)
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
                  for (final line in _lines)
                    _ReturnLineCard(
                      row: line,
                      validator: (value) =>
                          _validateReturnQuantity(value, line.item),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.createReturn),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHeaderCards(IncomingInvoice invoice) {
    final dateLabel = invoice.dateDisplay ??
        '${invoice.date.day.toString().padLeft(2, '0')}.'
            '${invoice.date.month.toString().padLeft(2, '0')}.'
            '${invoice.date.year}';

    return [
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
                label: AppStrings.incomingInvoiceNumber,
                value: invoice.number,
              ),
              if (!widget.createMode)
                _DetailRow(label: AppStrings.date, value: dateLabel),
              if (invoice.recipientWarehouseDisplay.isNotEmpty)
                _DetailRow(
                  label: AppStrings.recipient,
                  value: invoice.recipientWarehouseDisplay,
                ),
              if (invoice.senderWarehouseDisplay.isNotEmpty)
                _DetailRow(
                  label: AppStrings.sender,
                  value: invoice.senderWarehouseDisplay,
                ),
              if (widget.createMode) const CurrentUserAuthorRow(),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildViewContent() {
    final invoice = _invoice!;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(_buildHeaderCards(invoice)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Text(
              AppStrings.returnItems,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (invoice.items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                AppStrings.noReturnItems,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = invoice.items[index];
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
                    ),
                  );
                },
                childCount: invoice.items.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReturnLineRow {
  _ReturnLineRow({
    required this.item,
    required String quantityText,
  }) : quantityController = TextEditingController(text: quantityText);

  final IncomingInvoiceItem item;
  final TextEditingController quantityController;

  void dispose() {
    quantityController.dispose();
  }
}

class _ReturnLineCard extends StatelessWidget {
  const _ReturnLineCard({
    required this.row,
    required this.validator,
  });

  final _ReturnLineRow row;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final codeLabel = productCodeDisplayLabel(item.code ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
            const SizedBox(height: 8),
            OnScreenKeyboardTextField(
              controller: row.quantityController,
              decoration: InputDecoration(
                labelText: AppStrings.itemQuantity,
                helperText:
                    'Макс. ${formatQuantityForInput(item.quantity)}'
                    '${item.unit != null ? ' ${item.unit}' : ''}',
                suffix: item.unit != null && item.unit!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.unit!,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: AppColors.turquoiseDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      )
                    : null,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: const [QuantityInputFormatter()],
              validator: validator,
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
