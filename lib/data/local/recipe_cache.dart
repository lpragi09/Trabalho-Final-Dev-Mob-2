import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/recipe.dart';

class CachedSearch {
  const CachedSearch({required this.recipes, required this.savedAt});
  final List<Recipe> recipes;
  final DateTime savedAt;
}

/// Cache local das buscas (shared_preferences). Guarda só dados públicos da
/// API, nunca dados do usuário. Validade: [ttl]; acima disso é descartado.
class RecipeCache {
  RecipeCache(
    this._prefs, {
    this.ttl = const Duration(days: 7),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final Duration ttl;
  final DateTime Function() _now;

  static const _prefix = 'search_cache_v1:';
  static const _maxEntries = 20;

  String _key(String query) => '$_prefix${query.trim().toLowerCase()}';

  Future<void> save(String query, List<Recipe> recipes) async {
    final payload = jsonEncode({
      'savedAt': _now().toIso8601String(),
      'recipes': recipes.map((r) => r.toCache()).toList(),
    });
    await _prefs.setString(_key(query), payload);
    await _evictOldest();
  }

  CachedSearch? read(String query) {
    final raw = _prefs.getString(_key(query));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = DateTime.parse(json['savedAt'] as String);
      if (_now().difference(savedAt) > ttl) {
        _prefs.remove(_key(query));
        return null;
      }
      final recipes = (json['recipes'] as List)
          .cast<Map<String, dynamic>>()
          .map(Recipe.fromCache)
          .toList(growable: false);
      return CachedSearch(recipes: recipes, savedAt: savedAt);
    } on Object {
      // Entrada corrompida ou de versão antiga: invalida em vez de quebrar.
      _prefs.remove(_key(query));
      return null;
    }
  }

  Future<void> clear() async {
    for (final key
        in _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList()) {
      await _prefs.remove(key);
    }
  }

  Future<void> _evictOldest() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_prefix)).toList();
    if (keys.length <= _maxEntries) return;
    DateTime savedAtOf(String k) {
      try {
        final json = jsonDecode(_prefs.getString(k)!) as Map<String, dynamic>;
        return DateTime.parse(json['savedAt'] as String);
      } on Object {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    keys.sort((a, b) => savedAtOf(a).compareTo(savedAtOf(b)));
    for (final k in keys.take(keys.length - _maxEntries)) {
      await _prefs.remove(k);
    }
  }
}
