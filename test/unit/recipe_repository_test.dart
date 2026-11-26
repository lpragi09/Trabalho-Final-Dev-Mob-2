import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:minhas_receitas/core/result.dart';
import 'package:minhas_receitas/data/local/recipe_cache.dart';
import 'package:minhas_receitas/data/repositories/recipe_repository.dart';
import 'package:minhas_receitas/data/services/meal_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  var online = true;
  var now = DateTime(2026, 11, 20, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    online = true;
    now = DateTime(2026, 11, 20, 10);
  });

  RecipeRepositoryImpl buildRepo() {
    final client = MockClient((_) async {
      if (!online) throw http.ClientException('sem rede');
      return http.Response(
        '{"meals":[{"idMeal":"7","strMeal":"Brigadeiro"}]}',
        200,
      );
    });
    return RecipeRepositoryImpl(
      service: MealApiService(client: client),
      cache: RecipeCache(prefs, ttl: const Duration(days: 7), now: () => now),
    );
  }

  test('online: devolve dado da rede e grava no cache', () async {
    final result = await buildRepo().search('brigadeiro');
    final data = (result as Ok<RecipeSearchResult>).value;
    expect(data.origin, DataOrigin.network);
    expect(prefs.getKeys().any((k) => k.contains('brigadeiro')), isTrue);
  });

  test(
    'offline: devolve a última busca do cache sinalizando a origem',
    () async {
      final repo = buildRepo();
      await repo.search('Brigadeiro');
      online = false;
      now = now.add(const Duration(hours: 3));

      final result = await repo.search('brigadeiro');

      final data = (result as Ok<RecipeSearchResult>).value;
      expect(data.origin, DataOrigin.cache);
      expect(data.recipes.single.name, 'Brigadeiro');
      expect(data.cachedAt, DateTime(2026, 11, 20, 10));
    },
  );

  test('offline sem cache: propaga a falha de rede', () async {
    online = false;
    final result = await buildRepo().search('pudim');
    expect((result as Err).failure.kind, FailureKind.network);
  });

  test('cache vencido (mais de 7 dias) é invalidado', () async {
    final repo = buildRepo();
    await repo.search('brigadeiro');
    online = false;
    now = now.add(const Duration(days: 8));

    final result = await repo.search('brigadeiro');

    expect(result, isA<Err>());
    expect(prefs.getKeys().where((k) => k.contains('brigadeiro')), isEmpty);
  });
}
