import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/ui_state.dart';
import '../common/state_views.dart';
import 'saved_detail_view.dart';
import 'saved_recipes_viewmodel.dart';

class SavedListView extends StatelessWidget {
  const SavedListView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavedRecipesViewModel>();
    return switch (vm.state) {
      UiIdle() ||
      UiLoading() => const LoadingView(label: 'Carregando suas receitas...'),
      UiEmpty(:final message) => EmptyView(
        message: message,
        icon: Icons.bookmark_border,
      ),
      UiError(:final message) => ErrorView(message: message, onRetry: vm.load),
      UiSuccess(:final data) => ListView.separated(
        key: const Key('saved_list'),
        itemCount: data.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = data[i];
          return ListTile(
            key: Key('saved_${r.mealId}'),
            leading: RecipeThumb(url: r.thumbnailUrl),
            title: Text(r.title),
            subtitle: Text(
              '${'★' * r.rating}${'☆' * (5 - r.rating)}'
              '${r.note.isEmpty ? '' : '  ·  ${r.note}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: SavedDetailView(recipe: r),
                ),
              ),
            ),
          );
        },
      ),
    };
  }
}
