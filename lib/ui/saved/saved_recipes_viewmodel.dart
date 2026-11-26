import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../core/ui_state.dart';
import '../../data/repositories/saved_recipe_repository.dart';
import '../../data/services/dish_photo_service.dart';
import '../../domain/models/saved_recipe.dart';

class SavedRecipesViewModel extends ChangeNotifier {
  SavedRecipesViewModel({
    required SavedRecipeRepository repository,
    required this._photos,
    required this.uid,
  }) : _repo = repository {
    load();
  }

  final SavedRecipeRepository _repo;
  final DishPhotoService _photos;
  final String uid;

  StreamSubscription<List<SavedRecipe>>? _sub;
  UiState<List<SavedRecipe>> _state = const UiLoading();
  UiState<List<SavedRecipe>> get state => _state;

  void _emit(UiState<List<SavedRecipe>> s) {
    _state = s;
    notifyListeners();
  }

  void load() {
    _sub?.cancel();
    _emit(const UiLoading());
    _sub = _repo
        .watchAll(uid)
        .listen(
          (items) => _emit(
            items.isEmpty
                ? const UiEmpty(
                    'Você ainda não salvou receitas. Use a aba Buscar.',
                  )
                : UiSuccess(items),
          ),
          onError: (Object _) =>
              _emit(const UiError('Não foi possível carregar suas receitas.')),
        );
  }

  Future<String?> updateRecipe(
    SavedRecipe recipe, {
    required String note,
    required int rating,
  }) async {
    final invalid = SavedRecipe.validate(note: note, rating: rating);
    if (invalid != null) return invalid;
    final result = await _repo.update(
      recipe.copyWith(note: note.trim(), rating: rating),
    );
    return switch (result) {
      Ok() => null,
      Err(:final failure) => failure.message,
    };
  }

  Future<String?> delete(SavedRecipe recipe) async {
    final result = await _repo.delete(uid, recipe.id);
    if (result case Err(:final failure)) return failure.message;
    await _photos.deletePhoto(recipe.id);
    return null;
  }

  Future<PhotoOutcome> takePhoto(SavedRecipe r) => _photos.takePhoto(r.id);
  Future<PhotoOutcome> pickPhoto(SavedRecipe r) =>
      _photos.pickFromGallery(r.id);
  Future<String?> photoPath(SavedRecipe r) => _photos.photoPathFor(r.id);
  Future<void> removePhoto(SavedRecipe r) => _photos.deletePhoto(r.id);
  Future<bool> openSettings() => _photos.openSettings();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
