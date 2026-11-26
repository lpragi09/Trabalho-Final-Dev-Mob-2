import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:minhas_receitas/core/result.dart';
import 'package:minhas_receitas/data/services/meal_api_service.dart';

void main() {
  MealApiService serviceWith(MockClientHandler handler, {Duration? timeout}) =>
      MealApiService(
        client: MockClient(handler),
        timeout: timeout ?? const Duration(seconds: 2),
      );

  test('converte a resposta da API em lista de Recipe', () async {
    final service = serviceWith((req) async {
      expect(req.url.path, endsWith('/search.php'));
      expect(req.url.queryParameters['s'], 'chicken');
      return http.Response(
        jsonEncode({
          'meals': [
            {
              'idMeal': '1',
              'strMeal': ' Frango ',
              'strCategory': 'Chicken',
              'strArea': 'Brazilian',
            },
          ],
        }),
        200,
      );
    });

    final result = await service.search(' chicken ');

    final recipes = (result as Ok).value as List;
    expect(recipes.single.name, 'Frango');
    expect(recipes.single.area, 'Brazilian');
  });

  test('"meals": null vira lista vazia, não erro', () async {
    final service = serviceWith(
      (_) async => http.Response('{"meals": null}', 200),
    );
    final result = await service.search('xyz');
    expect((result as Ok).value, isEmpty);
  });

  test('status 500 vira falha de servidor', () async {
    final service = serviceWith((_) async => http.Response('erro', 500));
    final result = await service.search('cake');
    expect((result as Err).failure.kind, FailureKind.server);
  });

  test('JSON inválido ou item sem id vira falha de dados inválidos', () async {
    final broken = serviceWith((_) async => http.Response('<html>', 200));
    expect(
      ((await broken.search('cake')) as Err).failure.kind,
      FailureKind.invalidData,
    );

    final noId = serviceWith(
      (_) async => http.Response('{"meals":[{"strMeal":"Bolo"}]}', 200),
    );
    expect(
      ((await noId.search('cake')) as Err).failure.kind,
      FailureKind.invalidData,
    );
  });

  test('resposta lenta vira falha de timeout', () async {
    final service = serviceWith(
      (_) => Future.delayed(
        const Duration(milliseconds: 200),
        () => http.Response('{}', 200),
      ),
      timeout: const Duration(milliseconds: 50),
    );
    final result = await service.search('cake');
    expect((result as Err).failure.kind, FailureKind.timeout);
  });

  test('falha de conexão vira falha de rede', () async {
    final service = serviceWith(
      (_) async => throw http.ClientException('offline'),
    );
    final result = await service.search('cake');
    expect((result as Err).failure.kind, FailureKind.network);
  });
}
