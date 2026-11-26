import 'data/repositories/auth_repository.dart';
import 'data/repositories/recipe_repository.dart';
import 'data/repositories/saved_recipe_repository.dart';
import 'data/services/dish_photo_service.dart';

/// Composição das dependências. Produção usa Firebase/HTTP/plugins;
/// testes injetam implementações falsas pela mesma porta.
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.recipeRepository,
    required this.savedRecipeRepository,
    required this.photoService,
  });

  final AuthRepository authRepository;
  final RecipeRepository recipeRepository;
  final SavedRecipeRepository savedRecipeRepository;
  final DishPhotoService photoService;
}
