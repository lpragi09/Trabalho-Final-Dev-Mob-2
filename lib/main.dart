import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'data/local/recipe_cache.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/recipe_repository.dart';
import 'data/repositories/saved_recipe_repository.dart';
import 'data/services/dish_photo_service.dart';
import 'data/services/meal_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lê android/app/google-services.json (não versionado; ver README).
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();

  final deps = AppDependencies(
    authRepository: FirebaseAuthRepository(FirebaseAuth.instance),
    recipeRepository: RecipeRepositoryImpl(
      service: MealApiService(),
      cache: RecipeCache(prefs),
    ),
    savedRecipeRepository: FirestoreSavedRecipeRepository(
      FirebaseFirestore.instance,
    ),
    photoService: DeviceDishPhotoService(),
  );

  runApp(MinhasReceitasApp(deps: deps));
}
