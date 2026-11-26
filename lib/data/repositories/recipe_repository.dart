import '../../core/result.dart';
import '../../domain/models/recipe.dart';
import '../local/recipe_cache.dart';
import '../services/meal_api_service.dart';

enum DataOrigin { network, cache }

class RecipeSearchResult {
  const RecipeSearchResult({
    required this.recipes,
    required this.origin,
    this.cachedAt,
  });

  final List<Recipe> recipes;
  final DataOrigin origin;
  final DateTime? cachedAt;
}

abstract interface class RecipeRepository {
  Future<Result<RecipeSearchResult>> search(String query);
}

/// Estratégia network-first: tenta a API; se der certo, atualiza o cache.
/// Se a API falhar, devolve a última busca igual guardada no cache, marcando
/// a origem para a interface avisar que o dado pode estar desatualizado.
class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({required this._service, required this._cache});

  final MealApiService _service;
  final RecipeCache _cache;

  @override
  Future<Result<RecipeSearchResult>> search(String query) async {
    final remote = await _service.search(query);
    switch (remote) {
      case Ok(:final value):
        await _cache.save(query, value);
        return Ok(
          RecipeSearchResult(recipes: value, origin: DataOrigin.network),
        );
      case Err(:final failure):
        final cached = _cache.read(query);
        if (cached != null) {
          return Ok(
            RecipeSearchResult(
              recipes: cached.recipes,
              origin: DataOrigin.cache,
              cachedAt: cached.savedAt,
            ),
          );
        }
        return Err(failure);
    }
  }
}
