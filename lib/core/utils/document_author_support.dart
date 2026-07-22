import '../../core/di/injection.dart';
import '../../core/storage/auth_session_storage.dart';
import '../../core/storage/document_author_storage.dart';
import '../../core/utils/one_c_author.dart';

abstract final class DocumentAuthorSupport {
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

  static String? resolveLogin({
    required String documentId,
    String? authorLogin,
    String? author,
  }) {
    final fromApi = authorLogin?.trim().isNotEmpty == true
        ? authorLogin!.trim()
        : author?.trim().isNotEmpty == true
            ? author!.trim()
            : null;
    if (fromApi != null) return fromApi;
    return sl<DocumentAuthorStorage>().read(documentId);
  }
}
