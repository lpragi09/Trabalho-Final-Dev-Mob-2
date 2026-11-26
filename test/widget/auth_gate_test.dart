import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minhas_receitas/app.dart';

import '../support/fakes.dart';

void main() {
  testWidgets(
    'sem sessão mostra login; senha errada mostra erro; login abre área protegida',
    (tester) async {
      await tester.pumpWidget(MinhasReceitasApp(deps: fakeDependencies()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_submit')), findsOneWidget);
      expect(find.byKey(const Key('logout_button')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'ana@teste.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'errada1',
      );
      await tester.tap(find.byKey(const Key('auth_submit')));
      await tester.pumpAndSettle();
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'senha123',
      );
      await tester.tap(find.byKey(const Key('auth_submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('logout_button')), findsOneWidget);
      expect(find.byKey(const Key('search_field')), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('auth_submit')), findsOneWidget);
    },
  );
}
