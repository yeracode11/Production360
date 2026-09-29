import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/order_item_display.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../domain/entities/return_predata.dart';
import '../../../domain/entities/warehouse.dart';
import '../../../domain/repositories/return_repository.dart';
import '../../widgets/document_screen_scaffold.dart';
import 'incoming_invoice_screen.dart';

class CreateReturnScreen extends StatefulWidget {
  const CreateReturnScreen({
    super.key,
    required this.warehouse,
    this.predataFuture,
  });

  final Warehouse warehouse;
  final Future<ReturnPredata>? predataFuture;

  @override
  State<CreateReturnScreen> createState() => _CreateReturnScreenState();
}

class _CreateReturnScreenState extends State<CreateReturnScreen> {
  final _repository = sl<ReturnRepository>();
  final _searchController = TextEditingController();

  ReturnPredata? _predata;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _predata = _repository.peekCachedPredata(widget.warehouse.id);
    if (_predata != null) {
      _isLoading = false;
      final inFlight = widget.predataFuture;
      if (inFlight != null) {
        _applyPredataFuture(inFlight, silent: true);
      }
    } else {
      _loadPredata();
    }
  }

  Future<void> _applyPredataFuture(
    Future<ReturnPredata> future, {
    bool silent = false,
  }) async {
    if (!silent) {
      setState(() => _isRefreshing = true);
    }

    try {
      final predata = await future;
      if (!mounted) return;
      setState(() {
        _predata = predata;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_predata == null) {
          _loadError = exceptionMessage(e);
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadPredata({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = _predata == null;
      _loadError = null;
    });

    try {
      final predata = widget.predataFuture != null && !forceRefresh
          ? await widget.predataFuture!
          : await _repository.fetchPredata(
              warehouseId: widget.warehouse.id,
              forceRefresh: forceRefresh,
            );
      if (!mounted) return;
      setState(() {
        _predata = predata;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_predata == null) {
          _loadError = exceptionMessage(e);
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshPredata() async {
    setState(() => _isRefreshing = true);
    await _loadPredata(forceRefresh: true);
  }

  List<IncomingInvoiceSummary> _filterInvoices(
    List<IncomingInvoiceSummary> invoices,
  ) {
    final query = _searchQuery.trim();
    if (query.isEmpty) return invoices;
    return invoices.where((invoice) => invoice.matchesSearchQuery(query)).toList();
  }

  Future<void> _openInvoice(String invoiceId) async {
    final predata = _predata;
    if (predata == null) return;

    final invoiceFuture = _repository.getIncomingInvoiceById(
      invoiceId,
      warehouseId: widget.warehouse.id,
      warehouseName: widget.warehouse.name,
    );
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IncomingInvoiceScreen(
          invoiceId: invoiceId,
          invoiceFuture: invoiceFuture,
          createMode: true,
          warehouse: widget.warehouse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DocumentScreenScaffold(
      title: AppStrings.createReturnTitle,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorBody()
              : RefreshIndicator(
                  onRefresh: _refreshPredata,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildErrorBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
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
                    onPressed: _loadPredata,
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

  Widget _buildBody() {
    final predata = _predata;
    if (predata == null) {
      return const SizedBox.shrink();
    }

    final invoices = predata.incomingInvoices;
    final filteredInvoices = _filterInvoices(invoices);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
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
                _InfoRow(
                  label: AppStrings.recipient,
                  value: predata.recipientWarehouseDisplay(
                    widget.warehouse.name,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.selectIncomingInvoice,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (invoices.isNotEmpty) ...[
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: AppStrings.searchIncomingInvoiceHint,
              prefixIcon: Icon(Icons.search, color: AppColors.turquoiseDark),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: AppStrings.clearSearch,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceCard,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.surfaceMuted),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.turquoise,
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              AppStrings.noIncomingInvoices,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else if (filteredInvoices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.incomingInvoicesNotFound,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          )
        else
          ...List.generate(filteredInvoices.length, (index) {
            final invoice = filteredInvoices[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _openInvoice(invoice.id),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${AppStrings.incomingInvoiceNumber}${invoice.number}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            invoice.date,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                      if (invoice.senderWarehouseDisplay.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: AppStrings.sender,
                          value: invoice.senderWarehouseDisplay,
                        ),
                      ],
                      if (invoice.productsText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          formatProductLinesPreview(invoice.productsText),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.deepBrownLight,
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
