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
      throw _mapSocketException(e, trimmedHost, port);
    } on TimeoutException {
      throw _timeoutException(trimmedHost, port);
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
      throw _mapSocketException(e, trimmedHost, port);
    } on TimeoutException {
      throw _timeoutException(trimmedHost, port);
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

  NetworkPrinterException _timeoutException(String host, int port) {
    PrinterLog.error('Таймаут подключения $host:$port');
    return NetworkPrinterException(
      'Принтер не ответил за ${connectTimeout.inSeconds} с ($host:$port). '
      'Проверьте: принтер включён, IP на сетевом отчёте совпадает, '
      'шлюз принтера 192.168.2.1, телефон в Wi‑Fi 192.168.2.x, '
      'в настройках iOS разрешена локальная сеть для Production360.',
    );
  }

  NetworkPrinterException _mapSocketException(
    SocketException e,
    String host,
    int port,
  ) {
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
      return NetworkPrinterException(
        'Сеть недоступна ($host). IP принтера и телефона должны быть в одной '
        'подсети (например 192.168.2.x). Распечатайте сетевой отчёт.',
        cause: e,
      );
    }

    if (osMessage.toLowerCase().contains('timed out')) {
      return _timeoutException(host, port);
    }

    return NetworkPrinterException(
      'Не удалось подключиться к $host:$port ($osMessage). '
      'Проверьте IP, Wi‑Fi и разрешение «Локальная сеть» для приложения.',
      cause: e,
    );
  }
}
