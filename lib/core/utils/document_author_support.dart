import '../../core/di/injection.dart';
import '../../core/storage/auth_session_storage.dart';
import '../../core/storage/document_author_storage.dart';
import '../../core/utils/one_c_author.dart';

abstract final class DocumentAuthorSupport {
  /// Документы, детали которых уже запрашивались за этот запуск приложения:
  /// если и в деталях автора нет, не дёргаем 1С на каждом обновлении списка.
  static final Set<String> _detailsRequested = {};

  static String? _pickLogin({
    String? authorLogin,
    String? author,
  }) {
    for (final candidate in [authorLogin, author]) {
      final value = candidate?.trim();
      if (value == null || value.isEmpty) continue;
      if (OneCAuthorFields.isServiceAccount(value)) continue;
      return value;
    }
    return null;
  }

  static Future<void> rememberCreatedDocument({
    required String documentId,
    Map<String, dynamic>? responseJson,
  }) async {
    if (documentId.isEmpty) return;

    final fromApi = OneCAuthorFields.parse(responseJson ?? const {}).login;
    final login = fromApi ?? sl<AuthSessionStorage>().readCredentials()?.username;
    if (login == null || login.isEmpty) return;
    if (OneCAuthorFields.isServiceAccount(login)) return;

    await sl<DocumentAuthorStorage>().save(
      documentId: documentId,
      login: login,
    );
  }

  /// Сохранить автора из ответа 1С (список/детали) для карточек в списке.
  static Future<void> cacheDocumentAuthor({
    required String documentId,
    String? authorLogin,
    String? author,
  }) async {
    final login = _pickLogin(authorLogin: authorLogin, author: author);
    if (login == null) return;

    await sl<DocumentAuthorStorage>().save(
      documentId: documentId,
      login: login,
    );
  }

  /// Догрузить автора из деталей документа для тех, у кого его нет
  /// ни в ответе списка, ни в локальном кэше.
  ///
  /// В списках 1С отдаёт в «Автор» служебного пользователя (svc_mobile), а
  /// реальный автор есть только в деталях. [loadDetails] — метод репозитория
  /// «получить документ по id», он сам кладёт автора в кэш. Ошибки не
  /// пробрасываются: список должен открыться, даже если детали не загрузились.
  /// Каждый документ догружается один раз, дальше автор берётся из кэша.
  static Future<void> loadMissingAuthors({
    required Iterable<String> documentIds,
    required Future<Object?> Function(String documentId) loadDetails,
    int concurrency = 4,
  }) async {
    final queue = documentIds
        .where((id) => id.isNotEmpty)
        .where((id) => sl<DocumentAuthorStorage>().read(id) == null)
        .where(_detailsRequested.add)
        .toSet()
        .toList();
    if (queue.isEmpty) return;

    var next = 0;
    Future<void> worker() async {
      while (next < queue.length) {
        final id = queue[next++];
        try {
          await loadDetails(id);
        } catch (_) {
          // Автор пока останется «—»; попробуем снова при следующей загрузке.
          _detailsRequested.remove(id);
        }
      }
    }

    await Future.wait(
      List.generate(
        concurrency < queue.length ? concurrency : queue.length,
        (_) => worker(),
      ),
    );
  }

  static String? resolveLogin({
    required String documentId,
    String? authorLogin,
    String? author,
  }) {
    final fromDocument = _pickLogin(authorLogin: authorLogin, author: author);
    if (fromDocument != null) return fromDocument;
    return sl<DocumentAuthorStorage>().read(documentId);
  }

  static String? resolveDisplayLogin({
    required String documentId,
    String? authorLogin,
    String? author,
    String? currentUserLogin,
  }) {
    final resolved = resolveLogin(
      documentId: documentId,
      authorLogin: authorLogin,
      author: author,
    );
    if (resolved != null && resolved.isNotEmpty) return resolved;

    final current = currentUserLogin?.trim();
    return current?.isNotEmpty == true ? current : null;
  }
}
