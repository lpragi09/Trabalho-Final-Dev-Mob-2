import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/ui_state.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../domain/models/recipe.dart';
import '../common/state_views.dart';
import 'search_viewmodel.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(SearchViewModel vm) {
    FocusScope.of(context).unfocus();
    vm.search(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            key: const Key('search_field'),
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(vm),
            decoration: InputDecoration(
              hintText: 'Buscar receita (ex.: chicken, cake)',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                key: const Key('search_button'),
                icon: const Icon(Icons.search),
                onPressed: () => _search(vm),
              ),
            ),
          ),
        ),
        Expanded(
          child: switch (vm.state) {
            UiIdle() => const EmptyView(
              message: 'Pesquise uma receita pelo nome em inglês.',
              icon: Icons.restaurant_menu,
            ),
            UiLoading() => const LoadingView(label: 'Buscando receitas...'),
            UiEmpty(:final message) => EmptyView(message: message),
            UiError(:final message) => ErrorView(
              message: message,
              onRetry: vm.retry,
            ),
            UiSuccess(:final data) => _Results(result: data),
          },
        ),
      ],
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({required this.result});
  final RecipeSearchResult result;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SearchViewModel>();
    final fromCache = result.origin == DataOrigin.cache;
    return Column(
      children: [
        if (fromCache)
          MaterialBanner(
            key: const Key('cache_banner'),
            leading: const Icon(Icons.offline_bolt),
            content: Text(
              'Sem conexão: mostrando resultado salvo em '
              '${DateFormat('dd/MM HH:mm').format(result.cachedAt!)}.',
            ),
            actions: [
              TextButton(onPressed: vm.retry, child: const Text('Atualizar')),
            ],
          ),
        Expanded(
          child: ListView.separated(
            key: const Key('results_list'),
            itemCount: result.recipes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _ResultTile(recipe: result.recipes[i]),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.recipe});
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final r = recipe;
    final saving = context.select<SearchViewModel, bool>(
      (v) => v.isSaving(r.id),
    );
    return ListTile(
      key: Key('result_${r.id}'),
      leading: RecipeThumb(url: r.thumbnailUrl),
      title: Text(r.name),
      subtitle: Text(
        [r.category, r.area].where((s) => s.isNotEmpty).join(' · '),
      ),
      trailing: saving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : IconButton(
              key: Key('save_${r.id}'),
              tooltip: 'Salvar',
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final msg = await context.read<SearchViewModel>().save(r);
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(msg)));
              },
            ),
    );
  }
}
