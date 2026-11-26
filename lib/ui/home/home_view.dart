import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../app_dependencies.dart';
import '../auth/auth_viewmodel.dart';
import '../saved/saved_list_view.dart';
import '../saved/saved_recipes_viewmodel.dart';
import '../search/search_view.dart';
import '../search/search_viewmodel.dart';

/// Tela protegida: só é montada quando existe usuário na sessão.
class HomeView extends StatefulWidget {
  const HomeView({super.key, required this.uid, required this.email});
  final String uid;
  final String email;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final deps = context.read<AppDependencies>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SearchViewModel(
            recipes: deps.recipeRepository,
            saved: deps.savedRecipeRepository,
            uid: widget.uid,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SavedRecipesViewModel(
            repository: deps.savedRecipeRepository,
            photos: deps.photoService,
            uid: widget.uid,
          ),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tab == 0 ? 'Buscar receitas' : 'Minhas receitas'),
          actions: [
            IconButton(
              key: const Key('logout_button'),
              tooltip: 'Sair (${widget.email})',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthViewModel>().signOut(),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: const [SearchView(), SavedListView()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              key: Key('tab_search'),
              icon: Icon(Icons.search),
              label: 'Buscar',
            ),
            NavigationDestination(
              key: Key('tab_saved'),
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Minhas receitas',
            ),
          ],
        ),
      ),
    );
  }
}
