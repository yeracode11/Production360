import '../../core/di/injection.dart';
import '../../core/storage/auth_session_storage.dart';
import '../../core/storage/document_author_storage.dart';
import '../../core/utils/one_c_author.dart';

abstract final class DocumentAuthorSupport {
  static String? _pickLogin({
    String? authorLogin,
    String? author,
  }) {
    if (authorLogin?.trim().isNotEmpty == true) {
      return authorLogin!.trim();
    }
    if (author?.trim().isNotEmpty == true) {
      return author!.trim();
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
