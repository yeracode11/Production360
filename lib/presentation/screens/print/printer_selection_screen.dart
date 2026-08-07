import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../data/services/network_printer_client.dart';
import '../../../domain/entities/printable_document.dart';
import '../../../domain/entities/printer_config.dart';
import '../../../domain/entities/warehouse_printer.dart';
import '../../../domain/repositories/printer_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/printer_log_dialog.dart';

/// Выбор принтера перед печатью документа.
class PrinterSelectionScreen extends StatefulWidget {
  const PrinterSelectionScreen({super.key, required this.document});

  final PrintableDocument document;

  @override
  State<PrinterSelectionScreen> createState() => _PrinterSelectionScreenState();
}

class _PrinterSelectionScreenState extends State<PrinterSelectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  List<WarehousePrinter> _printers = const [];
  String? _selectedAddress;
  String? _warehouseId;
  String? _warehouseName;
  String? _loadError;
  bool _isLoading = true;
  bool _isPrinting = false;

  bool get _useManualEntry => _printers.isEmpty;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController(
      text: PrinterConfig.defaultPort.toString(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureLoadedForCurrentWarehouse();
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _ensureLoadedForCurrentWarehouse() {
    final state = context.read<WarehouseCubit>().state;
    if (state is! WarehouseLoaded) return;

    final warehouse = state.selectedWarehouse;
    if (_warehouseId == warehouse.id && !_isLoading) return;
    if (_warehouseId == warehouse.id && _isLoading) return;

    _loadPrinters(
      warehouseId: warehouse.id,
      warehouseName: warehouse.name,
    );
  }

  Future<void> _loadPrinters({
    required String warehouseId,
    required String warehouseName,
  }) async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _warehouseId = warehouseId;
      _warehouseName = warehouseName;
    });

    try {
      final repository = sl<PrinterRepository>();
      final printers =
          await repository.fetchWarehousePrinters(warehouseId);
      final saved = await repository.getConfig(warehouseId);

      if (!mounted || _warehouseId != warehouseId) return;

      String? selectedAddress;

      if (saved != null) {
        for (final printer in printers) {
          final parsed = PrinterConfig.fromAddress(printer.address);
          if (parsed.host == saved.host && parsed.port == saved.port) {
            selectedAddress = printer.address;
            break;
          }
        }
        if (selectedAddress == null && printers.isEmpty) {
          _hostController.text = saved.host;
          _portController.text = saved.port.toString();
        } else if (selectedAddress == null && printers.isNotEmpty) {
          selectedAddress = _matchSavedToListAddress(saved, printers);
        }
      } else if (printers.length == 1) {
        selectedAddress = printers.first.address;
      }

      setState(() {
        _printers = printers;
        _selectedAddress = selectedAddress;
        if (selectedAddress != null) {
          _applyPrinterAddress(selectedAddress);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || _warehouseId != warehouseId) return;

      PrinterConfig? saved;
      try {
        saved = await sl<PrinterRepository>().getConfig(warehouseId);
      } catch (_) {}

      if (!mounted || _warehouseId != warehouseId) return;

      setState(() {
        _loadError = exceptionMessage(e);
        _printers = const [];
        _isLoading = false;
        if (saved != null) {
          _hostController.text = saved.host;
          _portController.text = saved.port.toString();
        }
      });
    }
  }

  void _applyPrinterAddress(String address) {
    final config = PrinterConfig.fromAddress(address);
    _hostController.text = config.host;
    _portController.text = config.port.toString();
  }

  String? _matchSavedToListAddress(
    PrinterConfig saved,
    List<WarehousePrinter> printers,
  ) {
    for (final printer in printers) {
      final parsed = PrinterConfig.fromAddress(printer.address);
      if (parsed.host == saved.host) {
        return printer.address;
      }
    }
    return null;
  }

  int? _parsePort(String value) {
    final port = int.tryParse(value.trim());
    if (port == null || port <= 0 || port > 65535) return null;
    return port;
  }

  PrinterConfig? _buildConfigFromForm() {
    final host = _hostController.text.trim();
    final port = _parsePort(_portController.text);
    if (host.isEmpty || port == null) return null;
    return PrinterConfig(host: host, port: port);
  }

  WarehousePrinter? get _selectedPrinter {
    final address = _selectedAddress;
    if (address == null) return null;
    for (final printer in _printers) {
      if (printer.address == address) return printer;
    }
    return null;
  }

  String? _validateSelection() {
    if (_useManualEntry) return null;
    if (_selectedAddress == null) {
      return AppStrings.printerSelectRequired;
    }
    return null;
  }

  Future<void> _print() async {
    final warehouseId = _warehouseId;
    if (warehouseId == null) return;

    final selectionError = _validateSelection();
    if (selectionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(selectionError)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfigFromForm();
    if (config == null) return;

    setState(() => _isPrinting = true);
    try {
      final repository = sl<PrinterRepository>();
      await repository.saveConfig(
        warehouseId: warehouseId,
        config: config,
        printerName: _selectedPrinter?.name,
      );
      await repository.printDocument(
        widget.document,
        warehouseId: warehouseId,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.printSuccess)),
      );
    } on NetworkPrinterException catch (e) {
      if (!mounted) return;
      _showPrinterError(e.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exceptionMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  void _showPrinterError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        action: SnackBarAction(
          label: AppStrings.printerShowLog,
          textColor: Colors.white,
          onPressed: () => showPrinterLogDialog(
            context,
            title: AppStrings.printerLogTitle,
            message: message,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithKeyboard(title: AppStrings.printerSelectionTitle),
      body: BlocListener<WarehouseCubit, WarehouseState>(
        listenWhen: (previous, current) {
          if (current is! WarehouseLoaded) return false;
          if (previous is! WarehouseLoaded) return true;
          return previous.selectedWarehouse.id !=
              current.selectedWarehouse.id;
        },
        listener: (context, state) {
          if (state is! WarehouseLoaded) return;
          _loadPrinters(
            warehouseId: state.selectedWarehouse.id,
            warehouseName: state.selectedWarehouse.name,
          );
        },
        child: BlocBuilder<WarehouseCubit, WarehouseState>(
          builder: (context, warehouseState) {
            if (warehouseState is! WarehouseLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return DismissKeyboard.onTap(
              context,
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_warehouseName != null)
                              _buildWarehouseCard(_warehouseName!),
                            if (_warehouseName != null)
                              const SizedBox(height: 16),
                            Text(
                              widget.document.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 16),
                            if (_loadError != null) ...[
                              Card(
                                color: AppColors.mismatchSoft,
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        _loadError!,
                                        style: TextStyle(
                                          color: AppColors.mismatchText,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          onPressed: _warehouseId == null
                                              ? null
                                              : () => _loadPrinters(
                                                    warehouseId: _warehouseId!,
                                                    warehouseName:
                                                        _warehouseName ??
                                                            '',
                                                  ),
                                          child: const Text(
                                            AppStrings.pullToRefresh,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_useManualEntry)
                              _buildManualFields()
                            else
                              _buildPrinterList(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: _isPrinting ? null : _print,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: AppColors.turquoiseDark,
                            foregroundColor: Colors.white,
                          ),
                          child: _isPrinting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(AppStrings.printDocument),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isPrinting
                              ? null
                              : () => showPrinterLogDialog(
                                    context,
                                    title: AppStrings.printerLogTitle,
                                  ),
                          child: const Text(AppStrings.printerLogTitle),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(String warehouseName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.store_outlined, color: AppColors.turquoiseDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.printerWarehouseTitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warehouseName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.printerListTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._printers.map((printer) {
          final selected = _selectedAddress == printer.address;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: selected
                    ? AppColors.turquoise
                    : AppColors.surfaceMuted,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedAddress = printer.address;
                  _applyPrinterAddress(printer.address);
                });
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? AppColors.turquoiseDark
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            printer.name.isNotEmpty
                                ? printer.name
                                : printer.address,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            printer.address,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildManualFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.printerManualEntry,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.printerListEmpty,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _hostController,
          decoration: const InputDecoration(
            labelText: AppStrings.printerHost,
            hintText: AppStrings.printerHostHint,
            prefixIcon: Icon(Icons.router_outlined),
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppStrings.printerHostRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _portController,
          decoration: const InputDecoration(
            labelText: AppStrings.printerPort,
            hintText: '9100',
            prefixIcon: Icon(Icons.settings_ethernet_outlined),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (_parsePort(value ?? '') == null) {
              return AppStrings.printerPortInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }
}
