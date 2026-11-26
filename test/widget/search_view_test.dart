import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:minhas_receitas/core/result.dart';
import 'package:minhas_receitas/data/repositories/recipe_repository.dart';
import 'package:minhas_receitas/ui/search/search_view.dart';
import 'package:minhas_receitas/ui/search/search_viewmodel.dart';
import 'package:provider/provider.dart';

import '../support/fakes.dart';

Widget _host(FakeRecipeRepository repo) => MaterialApp(
  home: Scaffold(
    body: ChangeNotifierProvider(
      create: (_) => SearchViewModel(
        recipes: repo,
        saved: InMemorySavedRecipeRepository(),
        uid: 'u1',
      ),
      child: const SearchView(),
    ),
  ),
);

void main() {
  testWidgets('erro mostra "Tentar novamente" e o retry exibe a lista', (
    tester,
  ) async {
    final repo = FakeRecipeRepository([
      const Err(
        AppFailure(
          FailureKind.timeout,
          'O serviço demorou demais para responder.',
        ),
      ),
      const Ok(
        RecipeSearchResult(recipes: fakeRecipes, origin: DataOrigin.network),
      ),
    ]);
    await tester.pumpWidget(_host(repo));

    await tester.enterText(find.byKey(const Key('search_field')), 'chicken');
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('state_error')), findsOneWidget);
    expect(
      find.text('O serviço demorou demais para responder.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('state_error')), findsNothing);
    expect(find.text('Teriyaki Chicken Casserole'), findsOneWidget);
    expect(find.byKey(const Key('cache_banner')), findsNothing);
  });

  testWidgets('resultado vindo do cache mostra o aviso de offline', (
    tester,
  ) async {
    final repo = FakeRecipeRepository([
      Ok(
        RecipeSearchResult(
          recipes: fakeRecipes,
          origin: DataOrigin.cache,
          cachedAt: DateTime(2026, 11, 25, 14, 30),
        ),
      ),
    ]);
    await tester.pumpWidget(_host(repo));

    await tester.enterText(find.byKey(const Key('search_field')), 'chicken');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cache_banner')), findsOneWidget);
    expect(find.textContaining('25/11 14:30'), findsOneWidget);
  });

  testWidgets('busca sem resultados mostra o estado vazio', (tester) async {
    final repo = FakeRecipeRepository([
      const Ok(RecipeSearchResult(recipes: [], origin: DataOrigin.network)),
    ]);
    await tester.pumpWidget(_host(repo));

    await tester.enterText(find.byKey(const Key('search_field')), 'zzzz');
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('state_empty')), findsOneWidget);
    expect(
      find.text('Nenhuma receita encontrada para "zzzz".'),
      findsOneWidget,
    );
  });
}
