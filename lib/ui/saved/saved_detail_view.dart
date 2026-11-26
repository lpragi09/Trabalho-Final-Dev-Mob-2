import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../data/services/dish_photo_service.dart';
import '../../domain/models/saved_recipe.dart';
import '../common/state_views.dart';
import 'saved_recipes_viewmodel.dart';

class SavedDetailView extends StatefulWidget {
  const SavedDetailView({super.key, required this.recipe});
  final SavedRecipe recipe;

  @override
  State<SavedDetailView> createState() => _SavedDetailViewState();
}

class _SavedDetailViewState extends State<SavedDetailView> {
  late final TextEditingController _note = TextEditingController(
    text: widget.recipe.note,
  );
  late int _rating = widget.recipe.rating;
  String? _photoPath;
  int _photoVersion = 0;
  bool _busy = false;

  SavedRecipesViewModel get _vm => context.read<SavedRecipesViewModel>();

  @override
  void initState() {
    super.initState();
    _refreshPhoto();
  }

  Future<void> _refreshPhoto() async {
    final p = await _vm.photoPath(widget.recipe);
    if (mounted) setState(() => _photoPath = p);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    setState(() => _busy = true);
    final error = await _vm.updateRecipe(
      widget.recipe,
      note: _note.text,
      rating: _rating,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    _toast(error ?? 'Alterações salvas.');
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remover receita?'),
        content: const Text(
          'A receita e a foto do prato guardada no aparelho serão apagadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm_delete'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await _vm.delete(widget.recipe);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handlePhoto(Future<PhotoOutcome> Function() action) async {
    final outcome = await action();
    if (!mounted) return;
    switch (outcome.status) {
      case PhotoStatus.saved:
        imageCache.clear();
        setState(() {
          _photoPath = outcome.path;
          _photoVersion++;
        });
        _toast('Foto guardada só neste aparelho.');
      case PhotoStatus.cancelled:
        _toast('Nenhuma foto escolhida.');
      case PhotoStatus.unavailable:
        _toast('Câmera indisponível. Use "Escolher da galeria".');
      case PhotoStatus.denied:
        _showDenied(permanent: false);
      case PhotoStatus.permanentlyDenied:
        _showDenied(permanent: true);
    }
  }

  void _showDenied({required bool permanent}) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        key: const Key('permission_dialog'),
        title: const Text('Sem acesso à câmera'),
        content: Text(
          permanent
              ? 'A permissão da câmera está bloqueada. Você pode liberar nas '
                    'Configurações ou escolher uma foto já existente.'
              : 'Sem a permissão não dá para tirar a foto agora. Você pode '
                    'escolher uma foto já existente, sem dar acesso à galeria inteira.',
        ),
        actions: [
          if (permanent)
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                _vm.openSettings();
              },
              child: const Text('Abrir configurações'),
            ),
          FilledButton(
            key: const Key('use_gallery'),
            onPressed: () {
              Navigator.pop(c);
              _handlePhoto(() => _vm.pickPhoto(widget.recipe));
            },
            child: const Text('Escolher da galeria'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.recipe;
    return Scaffold(
      appBar: AppBar(
        title: Text(r.title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            key: const Key('delete_button'),
            tooltip: 'Remover',
            icon: const Icon(Icons.delete_outline),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              RecipeThumb(url: r.thumbnailUrl, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  r.category,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Sua nota', style: Theme.of(context).textTheme.titleSmall),
          Row(
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  key: Key('star_$i'),
                  onPressed: () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('note_field'),
            controller: _note,
            maxLines: 4,
            maxLength: SavedRecipe.maxNoteLength,
            decoration: const InputDecoration(
              labelText: 'Anotações (ajustes, substituições...)',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton.icon(
            key: const Key('save_changes'),
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Salvar alterações'),
          ),
          const Divider(height: 40),
          Text(
            'Foto do seu prato',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          const Text(
            'A foto fica guardada apenas neste aparelho e é apagada junto com a receita.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (_photoPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_photoPath!),
                key: ValueKey('photo_$_photoVersion'),
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('take_photo'),
                onPressed: () => _handlePhoto(() => _vm.takePhoto(r)),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Tirar foto'),
              ),
              OutlinedButton.icon(
                key: const Key('pick_photo'),
                onPressed: () => _handlePhoto(() => _vm.pickPhoto(r)),
                icon: const Icon(Icons.photo_library),
                label: const Text('Escolher da galeria'),
              ),
              if (_photoPath != null)
                TextButton.icon(
                  onPressed: () async {
                    await _vm.removePhoto(r);
                    await _refreshPhoto();
                  },
                  icon: const Icon(Icons.hide_image_outlined),
                  label: const Text('Apagar foto'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
