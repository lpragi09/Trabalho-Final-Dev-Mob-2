import 'dart:async';
import 'dart:collection';

import 'package:minhas_receitas/app_dependencies.dart';
import 'package:minhas_receitas/core/result.dart';
import 'package:minhas_receitas/data/repositories/auth_repository.dart';
import 'package:minhas_receitas/data/repositories/recipe_repository.dart';
import 'package:minhas_receitas/data/repositories/saved_recipe_repository.dart';
import 'package:minhas_receitas/data/services/dish_photo_service.dart';
import 'package:minhas_receitas/domain/models/app_user.dart';
import 'package:minhas_receitas/domain/models/recipe.dart';
import 'package:minhas_receitas/domain/models/saved_recipe.dart';

/// Dados fictícios usados nos testes (nenhum acesso a produção).
const fakeRecipes = [
  Recipe(
    id: '52772',
    name: 'Teriyaki Chicken Casserole',
    category: 'Chicken',
    area: 'Japanese',
    thumbnailUrl: '',
    instructions: 'Preheat oven...',
  ),
  Recipe(
    id: '52795',
    name: 'Chicken Handi',
    category: 'Chicken',
    area: 'Indian',
    thumbnailUrl: '',
    instructions: 'Take a large pot...',
  ),
];

class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  final Map<String, String> _accounts = {'ana@teste.com': 'senha123'};
  AppUser? _current;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _current;

  @override
  Future<Result<AppUser>> signIn(String email, String password) async {
    if (_accounts[email.trim()] != password) {
      return const Err(
        AppFailure(FailureKind.auth, 'E-mail ou senha incorretos.'),
      );
    }
    return _login(email.trim());
  }

  @override
  Future<Result<AppUser>> signUp(String email, String password) async {
    if (_accounts.containsKey(email.trim())) {
      return const Err(
        AppFailure(FailureKind.auth, 'Já existe uma conta com este e-mail.'),
      );
    }
    _accounts[email.trim()] = password;
    return _login(email.trim());
  }

  Result<AppUser> _login(String email) {
    _current = AppUser(uid: 'uid-${email.hashCode.abs()}', email: email);
    _controller.add(_current);
    return Ok(_current!);
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }
}

/// Devolve respostas programadas em fila; a última se repete.
class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository([List<Result<RecipeSearchResult>>? responses])
    : _responses = Queue.of(
        responses ??
            [
              const Ok(
                RecipeSearchResult(
                  recipes: fakeRecipes,
                  origin: DataOrigin.network,
                ),
              ),
            ],
      );

  final Queue<Result<RecipeSearchResult>> _responses;
  final List<String> queries = [];
  Completer<void>? gate;

  @override
  Future<Result<RecipeSearchResult>> search(String query) async {
    queries.add(query);
    if (gate != null) await gate!.future;
    return _responses.length > 1 ? _responses.removeFirst() : _responses.first;
  }
}

class InMemorySavedRecipeRepository implements SavedRecipeRepository {
  final Map<String, Map<String, SavedRecipe>> _byUser = {};
  final _changes = StreamController<String>.broadcast();
  int _seq = 0;

  List<SavedRecipe> _list(String uid) {
    final items = (_byUser[uid] ?? {}).values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Stream<List<SavedRecipe>> watchAll(String uid) async* {
    yield _list(uid);
    yield* _changes.stream.where((u) => u == uid).map(_list);
  }

  @override
  Future<Result<SavedRecipe>> create(
    String uid,
    Recipe recipe, {
    String note = '',
    int rating = 3,
  }) async {
    final s = SavedRecipe(
      id: 'doc${_seq++}',
      ownerId: uid,
      mealId: recipe.id,
      title: recipe.name,
      category: recipe.category,
      thumbnailUrl: recipe.thumbnailUrl,
      note: note,
      rating: rating,
      updatedAt: DateTime.now(),
    );
    (_byUser[uid] ??= {})[s.id] = s;
    _changes.add(uid);
    return Ok(s);
  }

  @override
  Future<Result<void>> update(SavedRecipe recipe) async {
    final docs = _byUser[recipe.ownerId];
    if (docs == null || !docs.containsKey(recipe.id)) {
      return const Err(
        AppFailure(
          FailureKind.permission,
          'Operação negada pelas regras de segurança.',
        ),
      );
    }
    docs[recipe.id] = recipe.copyWith(updatedAt: DateTime.now());
    _changes.add(recipe.ownerId);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String uid, String id) async {
    _byUser[uid]?.remove(id);
    _changes.add(uid);
    return const Ok(null);
  }
}

class FakePhotoService implements DishPhotoService {
  PhotoStatus cameraResult = PhotoStatus.denied;
  final List<String> deleted = [];

  @override
  Future<PhotoOutcome> takePhoto(String id) async => PhotoOutcome(cameraResult);

  @override
  Future<PhotoOutcome> pickFromGallery(String id) async =>
      const PhotoOutcome(PhotoStatus.cancelled);

  @override
  Future<String?> photoPathFor(String id) async => null;

  @override
  Future<void> deletePhoto(String id) async => deleted.add(id);

  @override
  Future<bool> openSettings() async => true;
}

AppDependencies fakeDependencies({
  FakeAuthRepository? auth,
  FakeRecipeRepository? recipes,
  InMemorySavedRecipeRepository? saved,
  FakePhotoService? photos,
}) => AppDependencies(
  authRepository: auth ?? FakeAuthRepository(),
  recipeRepository: recipes ?? FakeRecipeRepository(),
  savedRecipeRepository: saved ?? InMemorySavedRecipeRepository(),
  photoService: photos ?? FakePhotoService(),
);
