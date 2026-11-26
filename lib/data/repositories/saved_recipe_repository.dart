import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/result.dart';
import '../../domain/models/recipe.dart';
import '../../domain/models/saved_recipe.dart';

abstract interface class SavedRecipeRepository {
  Stream<List<SavedRecipe>> watchAll(String uid);
  Future<Result<SavedRecipe>> create(
    String uid,
    Recipe recipe, {
    String note,
    int rating,
  });
  Future<Result<void>> update(SavedRecipe recipe);
  Future<Result<void>> delete(String uid, String id);
}

/// CRUD em users/{uid}/saved_recipes/{id}. O UID vem da sessão, nunca da UI.
class FirestoreSavedRecipeRepository implements SavedRecipeRepository {
  FirestoreSavedRecipeRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('saved_recipes');

  SavedRecipe _fromDoc(String uid, DocumentSnapshot<Map<String, dynamic>> d) {
    final data = d.data() ?? const {};
    final ts = data['updatedAt'];
    return SavedRecipe(
      id: d.id,
      ownerId: data['ownerId'] as String? ?? uid,
      mealId: data['mealId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      note: data['note'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 1,
      updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  @override
  Stream<List<SavedRecipe>> watchAll(String uid) => _col(uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => _fromDoc(uid, d)).toList(growable: false));

  @override
  Future<Result<SavedRecipe>> create(
    String uid,
    Recipe recipe, {
    String note = '',
    int rating = 3,
  }) async {
    final invalid = SavedRecipe.validate(note: note, rating: rating);
    if (invalid != null) {
      return Err(AppFailure(FailureKind.invalidData, invalid));
    }
    final ref = _col(uid).doc();
    final saved = SavedRecipe(
      id: ref.id,
      ownerId: uid,
      mealId: recipe.id,
      title: recipe.name,
      category: recipe.category,
      thumbnailUrl: recipe.thumbnailUrl,
      note: note,
      rating: rating,
      updatedAt: DateTime.now(),
    );
    return _guard(() async {
      await ref.set({
        'ownerId': uid,
        'mealId': saved.mealId,
        'title': saved.title,
        'category': saved.category,
        'thumbnailUrl': saved.thumbnailUrl,
        'note': saved.note,
        'rating': saved.rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return saved;
    });
  }

  @override
  Future<Result<void>> update(SavedRecipe recipe) async {
    final invalid = SavedRecipe.validate(
      note: recipe.note,
      rating: recipe.rating,
    );
    if (invalid != null) {
      return Err(AppFailure(FailureKind.invalidData, invalid));
    }
    return _guard(
      () => _col(recipe.ownerId).doc(recipe.id).update({
        'note': recipe.note,
        'rating': recipe.rating,
        'updatedAt': FieldValue.serverTimestamp(),
      }),
    );
  }

  @override
  Future<Result<void>> delete(String uid, String id) =>
      _guard(() => _col(uid).doc(id).delete());

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on FirebaseException catch (e) {
      final kind = e.code == 'permission-denied'
          ? FailureKind.permission
          : FailureKind.server;
      final msg = e.code == 'permission-denied'
          ? 'Operação negada pelas regras de segurança.'
          : 'Falha ao gravar no Firestore (${e.code}).';
      return Err(AppFailure(kind, msg));
    }
  }
}
