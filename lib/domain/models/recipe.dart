/// Receita vinda do serviço Web (TheMealDB).
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.area,
    required this.thumbnailUrl,
    required this.instructions,
  });

  final String id;
  final String name;
  final String category;
  final String area;
  final String thumbnailUrl;
  final String instructions;

  /// Converte um item de `meals` da API. Lança [FormatException] se faltar
  /// campo obrigatório, para o Service transformar em falha segura.
  factory Recipe.fromApi(Map<String, dynamic> json) {
    final id = json['idMeal'];
    final name = json['strMeal'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      throw const FormatException('Receita sem idMeal ou strMeal');
    }
    return Recipe(
      id: id,
      name: name.trim(),
      category: (json['strCategory'] as String?)?.trim() ?? '',
      area: (json['strArea'] as String?)?.trim() ?? '',
      thumbnailUrl: (json['strMealThumb'] as String?) ?? '',
      instructions: (json['strInstructions'] as String?)?.trim() ?? '',
    );
  }

  /// Formato usado no cache local (independente do formato da API).
  factory Recipe.fromCache(Map<String, dynamic> json) => Recipe(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String? ?? '',
    area: json['area'] as String? ?? '',
    thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    instructions: json['instructions'] as String? ?? '',
  );

  Map<String, dynamic> toCache() => {
    'id': id,
    'name': name,
    'category': category,
    'area': area,
    'thumbnailUrl': thumbnailUrl,
    'instructions': instructions,
  };
}
