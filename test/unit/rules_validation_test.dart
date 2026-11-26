import 'package:flutter_test/flutter_test.dart';
import 'package:minhas_receitas/domain/models/saved_recipe.dart';
import 'package:minhas_receitas/ui/auth/auth_viewmodel.dart';

void main() {
  group('SavedRecipe.validate (mesma regra de firestore.rules)', () {
    test('aceita nota de 1 a 5 e anotação até 500 caracteres', () {
      expect(SavedRecipe.validate(note: '', rating: 1), isNull);
      expect(SavedRecipe.validate(note: 'a' * 500, rating: 5), isNull);
    });

    test('recusa nota fora da faixa', () {
      expect(SavedRecipe.validate(note: '', rating: 0), isNotNull);
      expect(SavedRecipe.validate(note: '', rating: 6), isNotNull);
    });

    test('recusa anotação longa demais', () {
      expect(SavedRecipe.validate(note: 'a' * 501, rating: 3), isNotNull);
    });
  });

  group('AuthViewModel.validate', () {
    test('exige e-mail válido e senha com 6+ caracteres', () {
      expect(AuthViewModel.validate('ana@teste.com', 'senha123'), isNull);
      expect(AuthViewModel.validate('ana', 'senha123'), contains('e-mail'));
      expect(AuthViewModel.validate('ana@teste.com', '123'), contains('6'));
    });
  });
}
