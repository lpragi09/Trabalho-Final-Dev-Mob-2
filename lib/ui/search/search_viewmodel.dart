import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../core/ui_state.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/repositories/saved_recipe_repository.dart';
import '../../domain/models/recipe.dart';

class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required this._recipes,
    required this._saved,
    required this.uid,
  });

  final RecipeRepository _recipes;
  final SavedRecipeRepository _saved;
  final String uid;

  UiState<RecipeSearchResult> _state = const UiIdle();
  UiState<RecipeSearchResult> get state => _state;

  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  final Set<String> _savingIds = {};
  bool isSaving(String mealId) => _savingIds.contains(mealId);

  void _emit(UiState<RecipeSearchResult> s) {
    _state = s;
    notifyListeners();
  }

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      _emit(const UiEmpty('Digite pelo menos 2 letras para buscar.'));
      return;
    }
    _lastQuery = q;
    _emit(const UiLoading());
    final result = await _recipes.search(q);
    // Ignora resposta atrasada de uma busca anterior.
    if (q != _lastQuery) return;
    switch (result) {
      case Ok(:final value) when value.recipes.isEmpty:
        _emit(UiEmpty('Nenhuma receita encontrada para "$q".'));
      case Ok(:final value):
        _emit(UiSuccess(value));
      case Err(:final failure):
        _emit(UiError(failure.message));
    }
  }

  Future<void> retry() => search(_lastQuery);

  /// Salva no Firestore do usuário logado. Devolve a mensagem para a View.
  Future<String> save(Recipe recipe) async {
    _savingIds.add(recipe.id);
    notifyListeners();
    final result = await _saved.create(uid, recipe);
    _savingIds.remove(recipe.id);
    notifyListeners();
    return switch (result) {
      Ok() => '"${recipe.name}" salva em Minhas receitas.',
      Err(:final failure) => failure.message,
    };
  }
}
