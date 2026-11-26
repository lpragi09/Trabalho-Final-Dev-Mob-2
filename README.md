# Minhas Receitas

Trabalho final de **Desenvolvimento Mobile II** (Unilavras, 2º semestre/2026) — aplicação Flutter conectada.
Autor: Luiz Paulo Moreno Ragi.

Caderno de receitas pessoal: o usuário busca receitas na API pública [TheMealDB](https://www.themealdb.com/api.php),
salva as que quer guardar no **Cloud Firestore** (vinculadas ao seu UID), dá nota, escreve anotações e
pode fotografar o prato que fez (a foto fica só no aparelho). Buscas recentes ficam em cache e continuam
disponíveis sem internet.

## Requisitos atendidos

| Requisito | Onde |
|---|---|
| MVVM | `lib/ui/**/**_view.dart` → `**_viewmodel.dart` → `lib/data/repositories` → `lib/data/services` |
| Estados loading/sucesso/vazio/erro | `lib/core/ui_state.dart`, `lib/ui/common/state_views.dart` |
| Serviço Web | `lib/data/services/meal_api_service.dart` (timeout, status, JSON inválido) |
| Cache e offline | `lib/data/local/recipe_cache.dart`, `lib/data/repositories/recipe_repository.dart` |
| Autenticação e sessão | `lib/data/repositories/auth_repository.dart`, `lib/ui/auth/`, `AuthGate` em `lib/app.dart` |
| CRUD no Firestore por UID | `lib/data/repositories/saved_recipe_repository.dart` (`users/{uid}/saved_recipes`) |
| Regras permitida/negada | `firestore.rules`, testes em `rules_test/rules.test.js` |
| Recurso nativo (câmera) | `lib/data/services/dish_photo_service.dart`, `lib/ui/saved/saved_detail_view.dart` |
| Testes | `test/unit`, `test/widget`, `integration_test/app_flow_test.dart` |

## Ambiente

- Flutter 3.50.1 (stable) / Dart 3.14.0
- JDK 17 para o build Android; JDK 21 apenas para o emulador do Firestore (testes de regras)
- Android SDK 36, emulador Android 15 (API 35)

## Como reproduzir a partir de um clone limpo

1. **Configuração do Firebase (não versionada).** Crie um projeto Firebase, ative *Authentication → E-mail/senha*
   e *Cloud Firestore*, registre um app Android com o pacote `br.edu.unilavras.minhas_receitas` e coloque o
   `google-services.json` baixado em `android/app/google-services.json`. Publique `firestore.rules` no console
   (ou `firebase deploy --only firestore:rules`).
2. **Dependências, formatação e análise:**
   ```bash
   flutter pub get
   dart format --output=none --set-exit-if-changed .
   flutter analyze
   ```
3. **Testes de unidade e widget** (sem Firebase, usam fakes):
   ```bash
   flutter test
   ```
4. **Teste de integração** (em emulador ou aparelho Android; backend falso, não toca produção):
   ```bash
   flutter test integration_test/app_flow_test.dart -d <id-do-dispositivo>
   ```
5. **Testes das regras do Firestore** (Firebase Emulator, projeto `demo-`, exige JDK 21+):
   ```bash
   cd rules_test && npm install && npm test
   ```
6. **Executar:** `flutter run`
7. **Release assinado.** Crie uma chave própria (fora do repositório) e o arquivo `android/key.properties`
   (também fora do Git):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=minhas_receitas
   storeFile=C:/caminho/para/minhas_receitas.jks
   ```
   Depois:
   ```bash
   flutter build apk --release
   flutter build appbundle --release
   ```
   Saídas: `build/app/outputs/flutter-apk/app-release.apk` e `build/app/outputs/bundle/release/app-release.aab`.

## Segurança e privacidade

- `google-services.json`, `key.properties`, `*.jks`, `build/`, APK e AAB estão no `.gitignore`.
- A foto do prato é salva apenas no diretório privado do app (`dish_photos/<id>.jpg`), não é enviada ao
  Firestore nem aparece em logs, e é apagada quando a receita é removida.
- O cache local guarda apenas dados públicos da API (sem dados do usuário) e expira em 7 dias.

## Fontes e recursos externos

TheMealDB API; documentação do Flutter, Firebase (Auth, Firestore, Security Rules, Emulator Suite) e dos
pacotes `provider`, `http`, `shared_preferences`, `image_picker`, `permission_handler`, `path_provider`.
O desenvolvimento contou com apoio de assistente de IA (Claude) para geração e revisão de código.
