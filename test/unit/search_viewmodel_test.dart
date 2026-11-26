import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minhas_receitas/core/result.dart';
import 'package:minhas_receitas/core/ui_state.dart';
import 'package:minhas_receitas/data/repositories/recipe_repository.dart';
import 'package:minhas_receitas/ui/search/search_viewmodel.dart';

import '../support/fakes.dart';

void main() {
  SearchViewModel build(FakeRecipeRepository repo) => SearchViewModel(
    recipes: repo,
    saved: InMemorySavedRecipeRepository(),
    uid: 'u1',
  );

  test('transição idle -> loading -> success', () async {
    final repo = FakeRecipeRepository()..gate = Completer<void>();
    final vm = build(repo);
    expect(vm.state, isA<UiIdle>());

    final future = vm.search('chicken');
    expect(vm.state, isA<UiLoading>());

    repo.gate!.complete();
    await future;
    expect(vm.state, isA<UiSuccess<RecipeSearchResult>>());
    expect(
      (vm.state as UiSuccess<RecipeSearchResult>).data.recipes,
      hasLength(2),
    );
  });

  test('lista vazia vira estado vazio com o termo buscado', () async {
    final vm = build(
      FakeRecipeRepository([
        const Ok(RecipeSearchResult(recipes: [], origin: DataOrigin.network)),
      ]),
    );
    await vm.search('xyz');
    expect((vm.state as UiEmpty).message, contains('xyz'));
  });

  test('erro e recuperação pelo retry repetindo a mesma busca', () async {
    final repo = FakeRecipeRepository([
      const Err(AppFailure(FailureKind.network, 'Sem conexão com a internet.')),
      const Ok(
        RecipeSearchResult(recipes: fakeRecipes, origin: DataOrigin.network),
      ),
    ]);
    final vm = build(repo);

    await vm.search('chicken');
    expect((vm.state as UiError).message, 'Sem conexão com a internet.');

    await vm.retry();
    expect(vm.state, isA<UiSuccess<RecipeSearchResult>>());
    expect(repo.queries, ['chicken', 'chicken']);
  });

  test('busca curta não chama o repositório', () async {
    final repo = FakeRecipeRepository();
    final vm = build(repo);
    await vm.search(' a ');
    expect(vm.state, isA<UiEmpty>());
    expect(repo.queries, isEmpty);
  });
}
