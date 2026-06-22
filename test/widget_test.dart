import 'package:confectionery_logistics/app.dart';
import 'package:confectionery_logistics/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await configureDependencies();
  });

  testWidgets('Login screen is shown for unauthenticated users', (tester) async {
    await tester.pumpWidget(const ConfectioneryApp());
    await tester.pumpAndSettle();

    expect(find.text('Вход в систему'), findsOneWidget);
    expect(find.text('Логин'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });
}
