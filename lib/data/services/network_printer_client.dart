import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../core/utils/printer_log.dart';

class NetworkPrinterException implements Exception {
  NetworkPrinterException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Отправка RAW ESC/POS данных на сетевой принтер по TCP (порт 9100).
class NetworkPrinterClient {
  const NetworkPrinterClient({
    this.connectTimeout = const Duration(seconds: 10),
    this.chunkSize = 512,
    this.chunkDelay = const Duration(milliseconds: 30),
    this.postSendDelay = const Duration(milliseconds: 1200),
  });

  final Duration connectTimeout;
  final int chunkSize;
  final Duration chunkDelay;
  final Duration postSendDelay;

  /// Только проверка TCP-соединения без отправки данных.
  Future<void> verifyConnection({
    required String host,
    required int port,
  }) async {
    final trimmedHost = _requireHost(host);
    PrinterLog.info(
      'Проверка TCP $trimmedHost:$port (таймаут ${connectTimeout.inSeconds} с)',
    );
    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(
        trimmedHost,
        port,
        timeout: connectTimeout,
      );
      PrinterLog.info(
        'TCP соединение OK за ${stopwatch.elapsedMilliseconds} ms',
      );
    } on SocketException catch (e) {
      throw await _mapSocketException(e, trimmedHost, port);
    } on TimeoutException {
      throw await _timeoutException(trimmedHost, port);
    } finally {
      await socket?.close();
      if (socket != null) {
        PrinterLog.info('TCP соединение закрыто');
      }
    }
  }

  Future<void> send({
    required String host,
    required int port,
    required List<int> data,
  }) async {
    final trimmedHost = _requireHost(host);
    PrinterLog.info(
      'Печать: TCP $trimmedHost:$port, ${data.length} байт ESC/POS',
    );

    Socket? socket;
    final stopwatch = Stopwatch()..start();
    try {
      socket = await Socket.connect(
        trimmedHost,
        port,
        timeout: connectTimeout,
      );
      PrinterLog.info('Подключено за ${stopwatch.elapsedMilliseconds} ms');

      var chunkIndex = 0;
      for (var offset = 0; offset < data.length; offset += chunkSize) {
        final end = (offset + chunkSize < data.length)
            ? offset + chunkSize
            : data.length;
        final chunk = data.sublist(offset, end);
        socket.add(Uint8List.fromList(chunk));
        await socket.flush();
        chunkIndex++;
        PrinterLog.info(
          'Отправлен блок $chunkIndex: $offset–${end - 1} (${chunk.length} байт)',
        );
        if (end < data.length) {
          await Future<void>.delayed(chunkDelay);
        }
      }

      PrinterLog.info(
        'Все данные отправлены, пауза ${postSendDelay.inMilliseconds} ms '
        'перед закрытием',
      );
      await Future<void>.delayed(postSendDelay);
      PrinterLog.info('Печать завершена за ${stopwatch.elapsedMilliseconds} ms');
    } on SocketException catch (e) {
      throw await _mapSocketException(e, trimmedHost, port);
    } on TimeoutException {
      throw await _timeoutException(trimmedHost, port);
    } catch (e) {
      if (e is NetworkPrinterException) rethrow;
      PrinterLog.error('Неожиданная ошибка: $e');
      throw NetworkPrinterException(
        'Ошибка печати: ${e.toString().replaceFirst('Exception: ', '')}',
        cause: e,
      );
    } finally {
      await socket?.close();
    }
  }

  String _requireHost(String host) {
    final trimmedHost = host.trim();
    if (trimmedHost.isEmpty) {
      throw NetworkPrinterException('Не указан IP-адрес принтера');
    }
    return trimmedHost;
  }

  Future<NetworkPrinterException> _timeoutException(
    String host,
    int port,
  ) async {
    PrinterLog.error('Таймаут подключения $host:$port');
    final hint = await _subnetHint(host);
    return NetworkPrinterException(
      'Принтер не ответил за ${connectTimeout.inSeconds} с ($host:$port). '
      '$hint',
    );
  }

  /// Подсказка на основе реального IP телефона, а не захардкоженной подсети.
  Future<String> _subnetHint(String host) async {
    final printerPrefix = _subnetPrefix(host);
    final phoneIps = await _localIPv4Addresses();
    PrinterLog.info(
      'IPv4 телефона: ${phoneIps.isEmpty ? '—' : phoneIps.join(', ')}',
    );

    if (printerPrefix != null && phoneIps.isNotEmpty) {
      final sameSubnet =
          phoneIps.any((ip) => _subnetPrefix(ip) == printerPrefix);
      if (!sameSubnet) {
        return 'Телефон в сети ${phoneIps.join(', ')}, а принтер $host — '
            'это разные подсети, телефон не достучится до принтера. '
            'Подключите телефон к Wi‑Fi сети $printerPrefix.x '
            'или смените IP принтера на адрес из сети телефона.';
      }
      return 'Телефон (${phoneIps.join(', ')}) и принтер в одной подсети. '
          'Проверьте: принтер включён и IP на его сетевом отчёте совпадает; '
          'в Настройках iOS → Конфиденциальность → Локальная сеть включён '
          'Production360; на роутере выключена изоляция клиентов Wi‑Fi.';
    }

    return 'Проверьте: принтер включён, IP на сетевом отчёте совпадает, '
        'телефон в той же Wi‑Fi сети, что и принтер, '
        'в настройках iOS разрешена локальная сеть для Production360.';
  }

  /// Первые три октета IPv4 (подсеть /24), либо null если это не IPv4.
  static String? _subnetPrefix(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4 || parts.any((p) => int.tryParse(p) == null)) {
      return null;
    }
    return parts.take(3).join('.');
  }

  static Future<List<String>> _localIPv4Addresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      return [
        for (final i in interfaces)
          for (final a in i.addresses)
            if (!a.isLinkLocal) a.address,
      ];
    } catch (e) {
      PrinterLog.error('Не удалось получить IP телефона: $e');
      return const [];
    }
  }

  Future<NetworkPrinterException> _mapSocketException(
    SocketException e,
    String host,
    int port,
  ) async {
    final code = e.osError?.errorCode;
    final osMessage = e.osError?.message ?? e.message;
    PrinterLog.error(
      'SocketException $host:$port — code=$code, message=$osMessage',
    );

    if (code == 61 || osMessage.toLowerCase().contains('refused')) {
      return NetworkPrinterException(
        'Порт $port на $host закрыт (connection refused). '
        'Включите RAW/JetDirect на принтере или проверьте порт на отчёте.',
        cause: e,
      );
    }

    if (code == 51 || code == 65 || osMessage.toLowerCase().contains('unreachable')) {
      final hint = await _subnetHint(host);
      return NetworkPrinterException(
        'Сеть недоступна ($host). $hint',
        cause: e,
      );
    }

    if (osMessage.toLowerCase().contains('timed out')) {
      return await _timeoutException(host, port);
    }

    return NetworkPrinterException(
      'Не удалось подключиться к $host:$port ($osMessage). '
      'Проверьте IP, Wi‑Fi и разрешение «Локальная сеть» для приложения.',
      cause: e,
    );
  }
}
