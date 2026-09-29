import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/exception_message.dart';
import '../../../data/services/network_printer_client.dart';
import '../../../domain/entities/printer_config.dart';
import '../../../domain/repositories/printer_repository.dart';
import '../../bloc/warehouse/warehouse_cubit.dart';
import '../../bloc/warehouse/warehouse_state.dart';
import '../../widgets/app_bar_with_keyboard.dart';
import '../../widgets/desktop_content_constraint.dart';
import '../../widgets/dismiss_keyboard.dart';
import '../../widgets/printer_log_dialog.dart';

/// Ручная настройка принтера для текущего склада.
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _hostController;
  late final TextEditingController _portController;

  String? _warehouseId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _portController = TextEditingController(
      text: PrinterConfig.defaultPort.toString(),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig(String warehouseId) async {
    setState(() {
      _isLoading = true;
      _warehouseId = warehouseId;
    });

    final config = await sl<PrinterRepository>().getConfig(warehouseId);
    if (!mounted || _warehouseId != warehouseId) return;

    setState(() {
      _hostController.text = config?.host ?? '';
      _portController.text =
          (config?.port ?? PrinterConfig.defaultPort).toString();
      _isLoading = false;
    });
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

  Future<void> _save() async {
    final warehouseId = _warehouseId;
    if (warehouseId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfigFromForm();
    if (config == null) return;

    setState(() => _isSaving = true);
    try {
      await sl<PrinterRepository>().saveConfig(
        warehouseId: warehouseId,
        config: config,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.printerSettingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exceptionMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _testConnection() async {
    final warehouseId = _warehouseId;
    if (warehouseId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfigFromForm();
    if (config == null) return;

    setState(() => _isCheckingConnection = true);
    try {
      final repository = sl<PrinterRepository>();
      await repository.saveConfig(warehouseId: warehouseId, config: config);
      await repository.verifyConnection(
        warehouseId: warehouseId,
        config: config,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.printerConnectionOk)),
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
      if (mounted) setState(() => _isCheckingConnection = false);
    }
  }

  Future<void> _testPrint() async {
    final warehouseId = _warehouseId;
    if (warehouseId == null) return;
    if (!_formKey.currentState!.validate()) return;

    final config = _buildConfigFromForm();
    if (config == null) return;

    setState(() => _isTesting = true);
    try {
      final repository = sl<PrinterRepository>();
      await repository.saveConfig(warehouseId: warehouseId, config: config);
      await repository.printTestPage(warehouseId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.printTestSuccess)),
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
      if (mounted) setState(() => _isTesting = false);
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
      appBar: AppBarWithKeyboard(title: AppStrings.printerSettings),
      body: DesktopContentConstraint(
        child: BlocBuilder<WarehouseCubit, WarehouseState>(
        builder: (context, state) {
          if (state is! WarehouseLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final warehouse = state.selectedWarehouse;
          if (_warehouseId != warehouse.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadConfig(warehouse.id);
            });
          }

          if (_isLoading && _warehouseId == warehouse.id) {
            return const Center(child: CircularProgressIndicator());
          }

          return DismissKeyboard.onTap(
            context,
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
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
                              AppStrings.printerWarehouseTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              warehouse.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.printerSettingsManualDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _hostController,
                      decoration: const InputDecoration(
                        labelText: AppStrings.printerHost,
                        hintText: AppStrings.printerHostHint,
                        prefixIcon: Icon(Icons.router_outlined),
                      ),
                      keyboardType: TextInputType.url,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (_parsePort(value ?? '') == null) {
                          return AppStrings.printerPortInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppColors.turquoiseDark,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(AppStrings.saveChanges),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                          _isCheckingConnection ? null : _testConnection,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isCheckingConnection
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.printerTestConnection),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _isTesting ? null : _testPrint,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: _isTesting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.printTestAction),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
