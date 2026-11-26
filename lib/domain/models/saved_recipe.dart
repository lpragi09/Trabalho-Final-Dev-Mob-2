/// Receita salva pelo usuário no Firestore (users/{uid}/saved_recipes/{id}).
class SavedRecipe {
  const SavedRecipe({
    required this.id,
    required this.ownerId,
    required this.mealId,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    required this.note,
    required this.rating,
    required this.updatedAt,
  });

  final String id;
  final String ownerId;
  final String mealId;
  final String title;
  final String category;
  final String thumbnailUrl;
  final String note;
  final int rating;
  final DateTime updatedAt;

  static const int maxNoteLength = 500;

  /// Regra de negócio validada no app e repetida em firestore.rules.
  static String? validate({required String note, required int rating}) {
    if (rating < 1 || rating > 5) return 'A nota deve ficar entre 1 e 5.';
    if (note.length > maxNoteLength) {
      return 'A anotação pode ter no máximo $maxNoteLength caracteres.';
    }
    return null;
  }

  SavedRecipe copyWith({String? note, int? rating, DateTime? updatedAt}) =>
      SavedRecipe(
        id: id,
        ownerId: ownerId,
        mealId: mealId,
        title: title,
        category: category,
        thumbnailUrl: thumbnailUrl,
        note: note ?? this.note,
        rating: rating ?? this.rating,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
