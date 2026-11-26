import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minhas_receitas/app.dart';
import 'package:minhas_receitas/data/services/dish_photo_service.dart';

import '../test/support/fakes.dart';

/// Jornada crítica no aparelho, com backend falso (sem tocar em produção):
/// cadastro -> busca -> salvar -> editar -> câmera negada -> remover -> logout.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('jornada principal do usuário', (tester) async {
    final saved = InMemorySavedRecipeRepository();
    final photos = FakePhotoService()..cameraResult = PhotoStatus.denied;
    await tester.pumpWidget(
      MinhasReceitasApp(
        deps: fakeDependencies(saved: saved, photos: photos),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Cadastro de conta fictícia
    await tester.tap(find.byKey(const Key('auth_toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('email_field')),
      'bia@teste.com',
    );
    await tester.enterText(find.byKey(const Key('password_field')), 'senha456');
    await tester.tap(find.byKey(const Key('auth_submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('logout_button')), findsOneWidget);

    // 2. Busca e salva uma receita (Create)
    await tester.enterText(find.byKey(const Key('search_field')), 'chicken');
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_52772')));
    await tester.pumpAndSettle();
    expect(find.textContaining('salva em Minhas receitas'), findsOneWidget);

    // 3. Lista (Read) e abre o detalhe
    await tester.tap(find.byKey(const Key('tab_saved')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved_52772')), findsOneWidget);
    await tester.tap(find.byKey(const Key('saved_52772')));
    await tester.pumpAndSettle();

    // 4. Edita nota e anotação (Update)
    await tester.tap(find.byKey(const Key('star_5')));
    await tester.enterText(
      find.byKey(const Key('note_field')),
      'Menos açúcar no molho',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save_changes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_changes')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Alterações salvas.'), findsOneWidget);
    await tester.pumpAndSettle();

    // 5. Câmera com permissão negada oferece alternativa
    await tester.ensureVisible(find.byKey(const Key('take_photo')));
    await tester.tap(find.byKey(const Key('take_photo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('permission_dialog')), findsOneWidget);
    expect(find.byKey(const Key('use_gallery')), findsOneWidget);
    await tester.tap(find.byKey(const Key('use_gallery')));
    await tester.pumpAndSettle();

    // 6. Remove (Delete) e confirma a limpeza da foto local
    await tester.tap(find.byKey(const Key('delete_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_delete')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('saved_52772')), findsNothing);
    expect(find.byKey(const Key('state_empty')), findsOneWidget);
    expect(photos.deleted, hasLength(1));

    // 7. Logout volta ao login
    await tester.tap(find.byKey(const Key('logout_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('auth_submit')), findsOneWidget);
  });
}
