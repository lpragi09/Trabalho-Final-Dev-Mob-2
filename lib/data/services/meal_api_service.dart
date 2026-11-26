import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/result.dart';
import '../../domain/models/recipe.dart';

/// Service: única classe que conhece HTTP e o formato JSON da TheMealDB.
class MealApiService {
  MealApiService({
    http.Client? client,
    this.baseUrl = 'https://www.themealdb.com/api/json/v1/1',
    this.timeout = const Duration(seconds: 8),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final Duration timeout;

  Future<Result<List<Recipe>>> search(String query) async {
    final uri = Uri.parse('$baseUrl/search.php')
        .replace(queryParameters: {'s': query.trim()});
    try {
      final response = await _client.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        return Err(
          AppFailure(
            FailureKind.server,
            'O serviço de receitas respondeu ${response.statusCode}.',
          ),
        );
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const FormatException('Corpo não é um objeto');
      }
      final meals = body['meals'];
      // A API devolve "meals": null quando não encontra nada.
      if (meals == null) return const Ok(<Recipe>[]);
      if (meals is! List) throw const FormatException('meals não é lista');
      final recipes = meals
          .whereType<Map<String, dynamic>>()
          .map(Recipe.fromApi)
          .toList(growable: false);
      return Ok(recipes);
    } on TimeoutException {
      return const Err(
        AppFailure(
          FailureKind.timeout,
          'O serviço demorou demais para responder.',
        ),
      );
    } on SocketException {
      return const Err(
        AppFailure(FailureKind.network, 'Sem conexão com a internet.'),
      );
    } on http.ClientException {
      return const Err(
        AppFailure(FailureKind.network, 'Falha de conexão com o serviço.'),
      );
    } on FormatException {
      return const Err(
        AppFailure(
          FailureKind.invalidData,
          'O serviço devolveu dados inválidos.',
        ),
      );
    }
  }
}
