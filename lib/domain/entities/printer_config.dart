import 'package:equatable/equatable.dart';

/// Настройки сетевого чекового принтера (ESC/POS, порт 9100 по умолчанию).
class PrinterConfig extends Equatable {
  const PrinterConfig({
    required this.host,
    this.port = defaultPort,
    this.displayName,
  });

  static const defaultPort = 9100;

  final String host;
  final int port;
  final String? displayName;

  bool get isConfigured => host.trim().isNotEmpty && port > 0 && port <= 65535;

  String get addressLabel => '$host:$port';

  PrinterConfig copyWith({String? host, int? port, String? displayName}) {
    return PrinterConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      displayName: displayName ?? this.displayName,
    );
  }

  /// Разбирает `192.168.10.60` или `192.168.10.60:9100` из 1С.
  static PrinterConfig fromAddress(String address, {String? displayName}) {
    final trimmed = address.trim();
    final colon = trimmed.lastIndexOf(':');
    if (colon > 0 && colon < trimmed.length - 1) {
      final host = trimmed.substring(0, colon).trim();
      final port = int.tryParse(trimmed.substring(colon + 1).trim());
      if (host.isNotEmpty && port != null && port > 0 && port <= 65535) {
        return PrinterConfig(
          host: host,
          port: port,
          displayName: displayName,
        );
      }
    }
    return PrinterConfig(
      host: trimmed,
      displayName: displayName,
    );
  }

  @override
  List<Object?> get props => [host, port, displayName];
}
