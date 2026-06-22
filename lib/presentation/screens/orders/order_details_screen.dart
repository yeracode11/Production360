import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/utils/receipt_display_name.dart';
import '../../../domain/entities/receipt_order_request.dart';
import '../../../domain/entities/order_item.dart';
import '../../../domain/entities/order_receipt_item.dart';
import '../../../domain/entities/order_request.dart';
import '../../../domain/repositories/order_repository.dart';
import '../../bloc/orders/orders_cubit.dart';
import '../../widgets/confirm_action_dialog.dart';
import '../../widgets/receipt_preview_item.dart';
import 'receipt_preview_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with SingleTickerProviderStateMixin {
  OrderRequest? _order;
  bool _isLoading = true;
  String? _loadError;
  late final TabController _tabController;
  List<_ReceiptFormRow> _receiptRows = [];
  bool _isSavingReceipt = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadOrder();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeReceiptRows();
    super.dispose();
  }

  void _disposeReceiptRows() {
    for (final row in _receiptRows) {
      row.dispose();
    }
    _receiptRows = [];
  }

  void _initReceiptRows(OrderRequest order) {
    _disposeReceiptRows();
    _receiptRows = order.receiptItems
        .map((item) => _ReceiptFormRow.fromItem(
              item,
              canEditReceipt: order.canEditReceipt,
            ))
        .toList();
  }

  Future<void> _loadOrder({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final order = await sl<OrderRepository>().getOrderById(widget.orderId);
      if (order == null) {
        setState(() {
          _loadError = 'Заявка не найдена';
          _isLoading = false;
        });
        return;
      }

      _initReceiptRows(order);
      setState(() {
        _order = order;
        if (showLoading) _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        if (showLoading) _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _deliveryDateLabel(OrderRequest order) {
    return order.deliveryDateDisplay ?? _formatDate(order.deliveryDate);
  }

  bool get _isReceiptComplete {
    if (_receiptRows.isEmpty) return false;

    for (final row in _receiptRows) {
      if (row.decision == ReceiptDecision.none) return false;
      if (row.decision == ReceiptDecision.accepted) {
        final received = int.tryParse(row.receivedController.text.trim());
        if (received == null || received < 0) return false;
      }
    }
    return true;
  }

  Future<void> _previewReceipt() async {
    final order = _order;
    if (order == null || !order.canEditReceipt || _isSavingReceipt) return;

    await openReceiptPreviewScreen(
      context,
      items: _buildReceiptPreviewItems(),
      orderNumber: order.orderNumber,
    );
  }

  Future<void> _saveReceipt() async {
    final order = _order;
    if (order == null || !order.canEditReceipt || _isSavingReceipt) return;

    if (!_isReceiptComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.receiptItemsIncomplete)),
      );
      return;
    }

    final items = _buildReceiptItems();
    if (items == null) return;

    final confirmed = await showConfirmActionDialog(
      context,
      message: AppStrings.receiptSaveConfirm,
    );
    if (!confirmed) return;

    await _performSaveReceipt(order, items);
  }

  List<ReceiptPreviewItem> _buildReceiptPreviewItems() {
    final order = _order;
    return _receiptRows.map((row) {
      final status = switch (row.decision) {
        ReceiptDecision.none => ReceiptItemPreviewStatus.pending,
        ReceiptDecision.accepted => ReceiptItemPreviewStatus.accepted,
        ReceiptDecision.rejected => ReceiptItemPreviewStatus.rejected,
      };
      final received = row.decision == ReceiptDecision.rejected
          ? 0
          : int.tryParse(row.receivedController.text.trim()) ??
              row.item.shipped;
      final displayName = order == null
          ? (isPlaceholderReceiptName(row.item.name) ? '' : row.item.name)
          : receiptItemDisplayName(
              item: row.item,
              orderItems: order.items,
            ) ??
              '';
      return ReceiptPreviewItem(
        name: displayName,
        unit: row.item.unit,
        ordered: row.item.ordered,
        shipped: row.item.shipped,
        status: status,
        received: received,
      );
    }).toList();
  }

  List<ReceiptOrderItemRequest>? _buildReceiptItems() {
    final items = <ReceiptOrderItemRequest>[];
    for (final row in _receiptRows) {
      if (row.decision == ReceiptDecision.rejected) {
        items.add(
          ReceiptOrderItemRequest(
            productId: row.item.id,
            shipped: row.item.shipped,
            received: 0,
          ),
        );
        continue;
      }

      final received = int.tryParse(row.receivedController.text.trim());
      if (received == null || received < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.itemQuantityInvalid}: ${row.item.name}'),
            backgroundColor: AppColors.error,
          ),
        );
        return null;
      }

      items.add(
        ReceiptOrderItemRequest(
          productId: row.item.id,
          shipped: row.item.shipped,
          received: received,
        ),
      );
    }
    return items;
  }

  Future<void> _performSaveReceipt(
    OrderRequest order,
    List<ReceiptOrderItemRequest> items,
  ) async {
    setState(() => _isSavingReceipt = true);

    try {
      await sl<OrderRepository>().submitReceipt(
        ReceiptOrderRequest(
          orderId: order.id,
          items: items,
        ),
      );

      if (mounted) {
        context.read<OrdersCubit>().refreshCurrentWarehouse();
        await _loadOrder(showLoading: false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.receiptSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingReceipt = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderDetailsTitle),
        bottom: _isLoading || _loadError != null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: AppStrings.orderDetailsTab),
                  Tab(text: AppStrings.receiptItems),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorBody()
              : _buildContent(_order!),
    );
  }

  Widget _buildErrorBody() {
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
              onPressed: _loadOrder,
              child: const Text(AppStrings.pullToRefresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(OrderRequest order) {
    final canEditReceipt = order.canEditReceipt;
    final showReceiptActions =
        canEditReceipt && _tabController.index == 1 && _receiptRows.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsTab(order),
              _buildReceiptTab(order, canEditReceipt),
            ],
          ),
        ),
        if (showReceiptActions)
          _buildReceiptBottomActions(
            isSaving: _isSavingReceipt,
            canSave: _isReceiptComplete,
          ),
      ],
    );
  }

  Widget _buildReceiptBottomActions({
    required bool isSaving,
    required bool canSave,
  }) {
    const buttonHeight = 48.0;
    const borderRadius = BorderRadius.all(Radius.circular(12));
    const labelStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: const Border(top: BorderSide(color: AppColors.surfaceMuted)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canSave && !isSaving)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    AppStrings.receiptItemsIncomplete,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isSaving ? null : _previewReceipt,
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text(
                        AppStrings.previewReceipt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: AppColors.turquoiseDark,
                        side: const BorderSide(
                          color: AppColors.turquoise,
                          width: 1.5,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: borderRadius,
                        ),
                        textStyle: labelStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (isSaving || !canSave) ? null : _saveReceipt,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(buttonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: AppColors.turquoiseDark,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.turquoiseDark.withValues(alpha: 0.35),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.9),
                        shape: const RoundedRectangleBorder(
                          borderRadius: borderRadius,
                        ),
                        textStyle: labelStyle,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    AppStrings.saveReceiptAction,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: labelStyle.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab(OrderRequest order) {
    final visibleItems = order.items
        .where((item) => orderItemDisplayName(item.name) != null)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    _ReadOnlyField(
                      label: AppStrings.orderNumber,
                      value: '№ ${order.orderNumber}',
                    ),
                    _ReadOnlyField(
                      label: AppStrings.status,
                      value: order.displayStatus,
                    ),
                    if (order.createdDateDisplay != null)
                      _ReadOnlyField(
                        label: AppStrings.createdDate,
                        value: order.createdDateDisplay!,
                      ),
                    if (order.orderType != null)
                      _ReadOnlyField(
                        label: AppStrings.orderType,
                        value: order.orderType!,
                      ),
                    if (order.organization != null)
                      _ReadOnlyField(
                        label: AppStrings.organizationSender,
                        value: order.organization!,
                      ),
                    if (order.warehouseName != null)
                      _ReadOnlyField(
                        label: AppStrings.warehouseSender,
                        value: order.warehouseName!,
                      ),
                    if (order.recipientOrganization != null)
                      _ReadOnlyField(
                        label: AppStrings.recipient,
                        value: order.recipientOrganization!,
                      ),
                    if (order.recipientWarehouse != null)
                      _ReadOnlyField(
                        label: AppStrings.orderingFor,
                        value: order.recipientWarehouse!,
                      ),
                    if (order.author != null && order.author!.isNotEmpty)
                      _ReadOnlyField(
                        label: AppStrings.author,
                        value: order.author!,
                      ),
                    _ReadOnlyField(
                      label: AppStrings.deliveryDate,
                      value: _deliveryDateLabel(order),
                    ),
                    _ReadOnlyField(
                      label: AppStrings.comment,
                      value: order.comment?.trim().isNotEmpty == true
                          ? order.comment!
                          : AppStrings.noComment,
                    ),
                  ],
                ),
              ),
            ),
            if (visibleItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                AppStrings.orderItems,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < visibleItems.length; i++)
                      _OrderItemRow(
                        item: visibleItems[i],
                        isLast: i == visibleItems.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTab(OrderRequest order, bool canEdit) {
    if (_receiptRows.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadOrder,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: Center(
                child: Text(
                  AppStrings.noReceiptItems,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.deepBrownLight,
                      ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final row in _receiptRows)
            _ReceiptCard(
              row: row,
              displayName: receiptItemDisplayName(
                item: row.item,
                orderItems: order.items,
              ),
              canEdit: canEdit,
              onChanged: () => setState(() {}),
            ),
        ],
      ),
    );
  }
}

enum ReceiptDecision { none, accepted, rejected }

class _ReceiptFormRow {
  _ReceiptFormRow({
    required this.item,
    required this.decision,
    required this.receivedController,
  });

  factory _ReceiptFormRow.fromItem(
    OrderReceiptItem item, {
    required bool canEditReceipt,
  }) {
    final decision = canEditReceipt
        ? (item.received > 0 ? ReceiptDecision.accepted : ReceiptDecision.none)
        : _decisionFromApi(item);

    return _ReceiptFormRow(
      item: item,
      decision: decision,
      receivedController: TextEditingController(
        text: item.received > 0
            ? item.received.toString()
            : item.shipped.toString(),
      ),
    );
  }

  /// После сохранения приёмки: received > 0 → принято, 0 при отгрузке → отклонено.
  static ReceiptDecision _decisionFromApi(OrderReceiptItem item) {
    if (item.received > 0) return ReceiptDecision.accepted;
    if (item.shipped > 0) return ReceiptDecision.rejected;
    return ReceiptDecision.none;
  }

  final OrderReceiptItem item;
  ReceiptDecision decision;
  final TextEditingController receivedController;

  void dispose() {
    receivedController.dispose();
  }
}


class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.row,
    required this.displayName,
    required this.canEdit,
    required this.onChanged,
  });

  final _ReceiptFormRow row;
  final String? displayName;
  final bool canEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final item = row.item;
    final isAccepted = row.decision == ReceiptDecision.accepted;
    final isRejected = row.decision == ReceiptDecision.rejected;

    final cardColor = isRejected
        ? AppColors.error.withValues(alpha: 0.12)
        : isAccepted
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceCard;

    final borderColor = isRejected
        ? AppColors.error.withValues(alpha: 0.45)
        : isAccepted
            ? AppColors.success.withValues(alpha: 0.45)
            : AppColors.surfaceMuted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Left: name + stats ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (displayName != null) ...[
                    Text(
                      displayName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isRejected
                                ? AppColors.error
                                : isAccepted
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '${AppStrings.itemOrdered}: ${item.ordered} ${item.unit} · '
                    '${AppStrings.itemShipped}: ${item.shipped} ${item.unit}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (canEdit && (isAccepted || isRejected)) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: TextFormField(
                        controller: row.receivedController,
                        keyboardType: TextInputType.number,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: AppStrings.receivedQuantity,
                          labelStyle:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                          suffixText: item.unit,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: isRejected
                              ? AppColors.error.withValues(alpha: 0.08)
                              : AppColors.success.withValues(alpha: 0.08),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: isRejected
                                    ? AppColors.error
                                    : AppColors.success),
                          ),
                        ),
                        onChanged: (_) => onChanged(),
                      ),
                    ),
                  ],
                  if (!canEdit) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.itemReceived}: ${item.received} ${item.unit}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isRejected
                                ? AppColors.error
                                : isAccepted
                                    ? AppColors.success
                                    : AppColors.turquoiseDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ── Right: action buttons ────────────────────────────────
            if (canEdit && !isAccepted && !isRejected) ...[
              _ActionButton(
                icon: Icons.check_rounded,
                color: AppColors.turquoiseDark,
                backgroundColor: AppColors.mintSoft,
                tooltip: AppStrings.acceptItem,
                onPressed: () {
                  row.decision = ReceiptDecision.accepted;
                  if (row.receivedController.text.trim().isEmpty) {
                    row.receivedController.text = item.shipped.toString();
                  }
                  onChanged();
                },
              ),
              const SizedBox(width: 6),
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.error,
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                tooltip: AppStrings.rejectItem,
                onPressed: () {
                  row.decision = ReceiptDecision.rejected;
                  if (row.receivedController.text.trim().isEmpty) {
                    row.receivedController.text = '0';
                  }
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item, required this.isLast});

  final OrderItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final displayName = orderItemDisplayName(item.name);

    return Column(
      children: [
        ListTile(
          title: displayName != null ? Text(displayName) : null,
          trailing: Text(
            item.quantityLabel,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.turquoiseDark,
                ),
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
